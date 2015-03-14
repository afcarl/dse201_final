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
      i           integer := 0;
      j           integer := 0;
      StartTime   timestamptz;
      EndTime     timestamptz;
      Delta       integer := 0;

		m_cursor refcursor;
		m_rec_cursor RECORD;
		
		c_query_six CURSOR FOR (with top_20_categories as (
			select id as category_id, category_name 
			from pcategory
			order by dollar_value desc
			limit 20
			), top_20_customers as (
			select id as customer_id, customer_name
			from pcustomer
			order by dollar_value desc
			limit 20
			)
			select tcat.category_name as top_category, tc.customer_name as top_customer, sum(s.quantity) as quantity_sold, sum(s.price) as dollar_value
			from sales s
			inner join top_20_customers as tc on s.uid=tc.customer_id
			inner join products as p on s.pid=p.id
			inner join top_20_categories as tcat on p.cid=tcat.category_id
			group by tcat.category_name, tc.customer_name
			order by dollar_value desc);
   BEGIN
		StartTime := clock_timestamp ();

		-- Start the timing of adding the cart items to DB.
		-- Add 1000 carts of ten items each
		FOR j IN 1 .. 1000
		LOOP
			PERFORM Transactions();
		END LOOP;
		
		EndTime := clock_timestamp ();
		
		Delta :=
			round (
			  1000
			* (extract (EPOCH FROM EndTime) - extract (EPOCH FROM StartTime)));
		RAISE NOTICE 'Duration of batch buy in millisecs=%' , Delta;
		
		CHECKPOINT;
		
		StartTime := clock_timestamp ();
		
      -- Queries

      -- 1.   Show the total sales (quantity sold and dollar value) for each customer.
		--OPEN m_cursor FOR 
			PERFORM * 
			FROM pcustomer;
		--LOOP
			--FETCH m_cursor INTO m_rec_cursor;
			--EXIT WHEN m_rec_cursor IS NULL;
			----RAISE NOTICE 'record=%', m_rec_cursor;
			--RAISE NOTICE 'user_id=% user_name=% quantity_sold=%, dollar_value=%', m_rec_cursor.id, m_rec_cursor.customer_name, m_rec_cursor.quantity_sold, m_rec_cursor.dollar_value;
		--END LOOP;
		--CLOSE m_cursor;

      -- 2.   Show the total sales for each state.
      
			PERFORM *
			FROM pstate;

      -- 3.   Show the total sales for each product, for a given customer. Only products
      --      that were actually bought by the given customer. Order by dollar value.
			PERFORM  *
			FROM pcustomer_product
			WHERE pcustomer_product.customer_name = 'user_1'
			ORDER BY dollar_value DESC;

      -- 4.   Show the total sales for each product and customer. Order by dollar value.
			PERFORM  *
			FROM pcustomer_product
			ORDER BY dollar_value DESC;

      -- 5.   Show the total sales for each product category and state.
			PERFORM *
			FROM pcategory_state;
			
	  -- 6.  For each combination of the top 20 product categories and top 20 customers, return all combinations
			open c_query_six;
			close c_query_six;

      EndTime := clock_timestamp ();
      Delta :=
         round (
              1000
            * (extract (EPOCH FROM EndTime) - extract (EPOCH FROM StartTime)));
      RAISE NOTICE 'Duration of queries in millisecs=%' , Delta;
   END;
   $$
   LANGUAGE plpgsql;
