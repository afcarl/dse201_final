CREATE OR REPLACE FUNCTION Transactions(uid_count integer, pid_count integer)
   RETURNS void
AS
   $$
   DECLARE
      random_uid   integer := 0;
      random_pid   integer := 0;
      random_qty   integer := 0;
      totalprice   integer := 0;
      i            integer := 0;
   BEGIN
      random_uid := mod ((round (random () * uid_count))::int, uid_count) + 1;

      FOR i IN 1 .. 10
      LOOP
         random_pid = mod ((round (random () * pid_count))::int, pid_count) + 1;
         random_qty = round (random () * 5) + 1;
         totalprice =
              random_qty
            * (SELECT p.listprice
               FROM products AS p
               WHERE p.id = random_pid);
         INSERT INTO sales (uid,
                            pid,
                            quantity,
                            price)
              VALUES (random_uid,
                      random_pid,
                      random_qty,
                      totalprice);
      -- Add triggers here to update precomputed tables.
      
      END LOOP;
   END;
   $$
   LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION Workload (num_iterations integer)
   RETURNS void
AS
   $$
   DECLARE
	
	num_users				integer := 0;
	num_products			integer := 0;
	i           			integer := 0;
	StartTime   			timestamptz;
	EndTime     			timestamptz;
	Query1StartTime			timestamptz;
	Delta       			integer := 0;
		
   BEGIN
		
		-- Determing the number of users and products BEFORE Transactions function
		-- so the timing of count(*) is not included
		num_users := (SELECT COUNT (*) FROM users);
		num_products := (SELECT COUNT (*) FROM products);
		
		StartTime := clock_timestamp ();

		-- Start the timing of adding the cart items to DB.
		-- Add 1000 carts of ten items each
		FOR i IN 1 .. 1000
		LOOP
			PERFORM Transactions(num_users, num_products);
		END LOOP;
		
		CHECKPOINT;
		
		EndTime := clock_timestamp ();
		Delta := round (1000 * (extract (EPOCH FROM EndTime) - extract (EPOCH FROM StartTime)));
		RAISE NOTICE 'Duration of batch buy in millisecs=%' , Delta;
		
      -- Queries

      -- 1.   Show the total sales (quantity sold and dollar value) for each customer.
			Query1StartTime := clock_timestamp();
			
			PERFORM users.name as customer_name, sum(sales.quantity) as quantity_sold, sum(sales.price) as dollar_value
			FROM users, sales 
			WHERE users.id = sales.uid
			GROUP BY users.name;
			
			EndTime := clock_timestamp ();
			Delta := round (1000 * (extract (EPOCH FROM EndTime) - extract (EPOCH FROM Query1StartTime)));
			RAISE NOTICE 'Duration of query 1 in millisecs=%' , Delta;

      -- 2.   Show the total sales for each state.
			StartTime := clock_timestamp();
			
			PERFORM states.name as state_name, sum(sales.quantity) as quantity_sold, sum(sales.price) as dollar_value
			FROM sales, users, states
			WHERE sales.uid = users.id AND 
				users.state = states.id
			GROUP BY states.name;
			
			Delta := round (1000 * (extract (EPOCH FROM EndTime) - extract (EPOCH FROM StartTime)));
			RAISE NOTICE 'Duration of query 2 in millisecs=%' , Delta;

      -- 3.   Show the total sales for each product, for a given customer. Only products
      --      that were actually bought by the given customer. Order by dollar value.
			StartTime := clock_timestamp();
			
			PERFORM products.sku as product_sku, sum(sales.quantity) as quantity_sold, sum(sales.price) as dollar_value
			FROM sales, products, users
			WHERE 	users.name = 'user_1' AND 
				sales.uid = users.id AND 
				products.id = sales.pid
			GROUP BY products.sku
			ORDER BY dollar_value;
			
			EndTime := clock_timestamp ();
			Delta := round (1000 * (extract (EPOCH FROM EndTime) - extract (EPOCH FROM StartTime)));
			RAISE NOTICE 'Duration of query 3 in millisecs=%' , Delta;

      -- 4.   Show the total sales for each product and customer. Order by dollar value.
			StartTime := clock_timestamp();
			
			PERFORM products.sku as product_sku, users.name as customer, sum(sales.quantity) as quantity_sold, sum(sales.price) as dollar_value
			FROM sales, products, users
			WHERE sales.uid = users.id AND 
				products.id = sales.pid
			GROUP BY products.sku, users.name
			ORDER BY dollar_value;
			
			EndTime := clock_timestamp ();
			Delta := round (1000 * (extract (EPOCH FROM EndTime) - extract (EPOCH FROM StartTime)));
			RAISE NOTICE 'Duration of query 4 in millisecs=%' , Delta;

      -- 5.   Show the total sales for each product category and state.
			StartTime := clock_timestamp();
			
			PERFORM states.name as state_name, categories.name as category_name, sum(sales.quantity) as total_quantity, sum(sales.price) as dollar_value
			FROM sales, products, users, categories, states
			WHERE sales.uid = users.id AND
				users.state = states.id AND
				products.id = sales.pid AND
				categories.id = products.cid
			GROUP BY states.name, categories.name;
			
			EndTime := clock_timestamp ();
			Delta := round (1000 * (extract (EPOCH FROM EndTime) - extract (EPOCH FROM StartTime)));
			RAISE NOTICE 'Duration of query 5 in millisecs=%' , Delta;
			
	  -- 6.  For each combination of the top 20 product categories and top 20 customers, return all combinations
			StartTime := clock_timestamp();
			
			PERFORM tcat.category_name as top_category, tc.customer_name as top_customer, sum(s.quantity) as quantity_sold, sum(s.price) as dollar_value
			from sales s
			inner join products as p on s.pid=p.id
			inner join (
				select c.id as category_id, c.name as category_name, sum(s.quantity) as quantity_sold, sum(s.price) as dollar_value
				from sales as s
				inner join products as p on s.pid=p.id
				inner join categories as c on p.cid=c.id
				group by c.id, c.name
				order by dollar_value desc
				limit 20
			) as tcat on p.cid=tcat.category_id
			inner join (
				select u.id as customer_id, u.name as customer_name, sum(s.quantity) as quantity_sold, sum(s.price) as dollar_value
				from sales as s
				inner join users as u on s.uid=u.id
				group by u.id, u.name
				order by dollar_value desc
				limit 20
			) as tc on s.uid=tc.customer_id
			group by tcat.category_name, tc.customer_name
			order by dollar_value desc;
			
			EndTime := clock_timestamp ();
			Delta := round (1000 * (extract (EPOCH FROM EndTime) - extract (EPOCH FROM StartTime)));
			RAISE NOTICE 'Duration of query 6 in millisecs=%' , Delta;
			
			Delta := round (1000 * (extract (EPOCH FROM EndTime) - extract (EPOCH FROM Query1StartTime)));
			RAISE NOTICE 'Duration of all queries combined in millisecs=%' , Delta;
			
   END;
   $$
   LANGUAGE plpgsql;
