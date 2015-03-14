-- Function: timer_test(text)

-- DROP FUNCTION timer_test(text);

CREATE OR REPLACE FUNCTION timer_test()
  RETURNS void AS
$BODY$
   DECLARE
   StartTime   timestamptz;
   EndTime     timestamptz;
   Delta       integer := 0;
   BEGIN
	StartTime := clock_timestamp();
	-- start query
	PERFORM  * FROM pcustomer_product WHERE pcustomer_product.customer_name = 'user_1' ORDER BY dollar_value DESC;
	-- end query
	EndTime := clock_timestamp();
	Delta :=
	 round (
	      1000
	    * (extract (EPOCH FROM EndTime) - extract (EPOCH FROM StartTime)));
	RAISE NOTICE 'Duration in millisecs=%' , Delta;
END;$BODY$
  LANGUAGE plpgsql;

