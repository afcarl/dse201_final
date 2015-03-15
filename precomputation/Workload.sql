CREATE OR REPLACE FUNCTION Transactions ()
   RETURNS void
AS
   $$
   DECLARE
      random_uid   integer := 0;
      uid_count    integer := (SELECT COUNT (*) FROM users);
      random_pid   integer := 0;
      pid_count    integer := (SELECT COUNT (*) FROM products);
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
      i           			integer := 0;
      StartTime   			timestamptz;
      EndTime     			timestamptz;
      Query1StartTime		timestamptz;
      Delta       			integer := 0;
		
   BEGIN
		StartTime := clock_timestamp ();

		-- Start the timing of adding the cart items to DB.
		-- Add 1000 carts of ten items each
		FOR i IN 1 .. 1000
		LOOP
			PERFORM Transactions();
		END LOOP;
		
		CHECKPOINT;
		
		EndTime := clock_timestamp ();
		Delta := round (1000 * (extract (EPOCH FROM EndTime) - extract (EPOCH FROM StartTime)));
		RAISE NOTICE 'Duration of batch buy in millisecs=%' , Delta;
		
      -- Queries

      -- 1.   Show the total sales (quantity sold and dollar value) for each customer.
			Query1StartTime := clock_timestamp();
			
			PERFORM * 
			FROM pcustomer;
			EndTime := clock_timestamp ();
			
			Delta := round (1000 * (extract (EPOCH FROM EndTime) - extract (EPOCH FROM Query1StartTime)));
			RAISE NOTICE 'Duration of query 1 in millisecs=%' , Delta;

      -- 2.   Show the total sales for each state.
			StartTime := clock_timestamp();
			
			PERFORM *
			FROM pstate;
			EndTime := clock_timestamp ();
			
			Delta := round (1000 * (extract (EPOCH FROM EndTime) - extract (EPOCH FROM StartTime)));
			RAISE NOTICE 'Duration of query 2 in millisecs=%' , Delta;

      -- 3.   Show the total sales for each product, for a given customer. Only products
      --      that were actually bought by the given customer. Order by dollar value.
			StartTime := clock_timestamp();
			
			PERFORM  *
			FROM pcustomer_product
			WHERE pcustomer_product.customer_name = 'user_1'
			ORDER BY dollar_value DESC;
			
			EndTime := clock_timestamp ();
			Delta := round (1000 * (extract (EPOCH FROM EndTime) - extract (EPOCH FROM StartTime)));
			RAISE NOTICE 'Duration of query 3 in millisecs=%' , Delta;

      -- 4.   Show the total sales for each product and customer. Order by dollar value.
			StartTime := clock_timestamp();
			
			PERFORM  *
			FROM pcustomer_product
			ORDER BY dollar_value DESC;
			
			EndTime := clock_timestamp ();
			Delta := round (1000 * (extract (EPOCH FROM EndTime) - extract (EPOCH FROM StartTime)));
			RAISE NOTICE 'Duration of query 4 in millisecs=%' , Delta;

      -- 5.   Show the total sales for each product category and state.
			StartTime := clock_timestamp();
			
			PERFORM *
			FROM pcategory_state;
			
			EndTime := clock_timestamp ();
			Delta := round (1000 * (extract (EPOCH FROM EndTime) - extract (EPOCH FROM StartTime)));
			RAISE NOTICE 'Duration of query 5 in millisecs=%' , Delta;
			
	  -- 6.  For each combination of the top 20 product categories and top 20 customers, return all combinations
			StartTime := clock_timestamp();
			
			PERFORM tcat.category_name as top_category, tc.customer_name as top_customer, sum(s.quantity) as quantity_sold, sum(s.price) as dollar_value
			from sales s
			inner join (
				select id as customer_id, customer_name
				from pcustomer
				order by dollar_value desc
				limit 20
			) as tc on s.uid=tc.customer_id
			inner join products as p on s.pid=p.id
			inner join (
				select id as category_id, category_name 
				from pcategory
				order by dollar_value desc
				limit 20
			) as tcat on p.cid=tcat.category_id
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
