-- Function: timer_test(text)

-- DROP FUNCTION timer_test(text);

CREATE OR REPLACE FUNCTION timer_test(user_name text)
  RETURNS void AS
$BODY$
DECLARE
   m_cursor refcursor;
   m_rec_cursor RECORD;
   StartTime   timestamptz;
   EndTime     timestamptz;
   Delta       integer := 0;
   BEGIN
	RAISE NOTICE 'querying using user % as parameter...', user_name;

	StartTime := clock_timestamp();
	-- start query
	OPEN m_cursor FOR 
		SELECT products.sku as product_sku, sum(sales.quantity) as quantity_sold, sum(sales.price) as dollar_value
		FROM sales, products, users
		WHERE   users.name = user_name AND
			sales.uid = users.id AND
			products.id = sales.pid
		GROUP BY products.sku
		ORDER BY dollar_value;
	-- end query
	EndTime := clock_timestamp();
	Delta :=
	 round (
	      1000
	    * (extract (EPOCH FROM EndTime) - extract (EPOCH FROM StartTime)));
	RAISE NOTICE 'Duration in millisecs=%' , Delta;

	-- process results
	LOOP
		FETCH m_cursor INTO m_rec_cursor;
		EXIT WHEN m_rec_cursor IS NULL;
		RAISE NOTICE 'record=%', m_rec_cursor;
		--RAISE NOTICE 'user_name= %, sku= %, quantity_sold=%, dollar_value=%', user_name, m_rec_cursor.product_sku, m_rec_cursor.quantity_sold, m_rec_cursor.dollar_value;
	END LOOP;
	CLOSE m_cursor;
END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION timer_test(text)
  OWNER TO conway;

