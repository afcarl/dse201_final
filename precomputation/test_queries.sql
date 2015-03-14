-- Function: execute_trigger_test()

CREATE OR REPLACE FUNCTION execute_trigger_test()
  RETURNS void AS
$BODY$
DECLARE
	random_uid   integer := 0;
	uid_count    integer := (SELECT COUNT (*) FROM users);
	random_pid   integer := 0;
	pid_count    integer := (SELECT COUNT (*) FROM products);
	random_qty   integer := 0;
	totalprice   integer := 0;
	m_rec_prev_pcategory_state			RECORD;
	m_rec_prev_pcategory	 			RECORD;
	m_rec_prev_pcustomer_product		RECORD;
	m_rec_prev_pstate					RECORD;
	m_rec_prev_pscustomers				RECORD;
	m_rec_new_pcategory_state			RECORD;
	m_rec_new_pcategory	 				RECORD;
	m_rec_new_pcustomer_product			RECORD;
	m_rec_new_pstate					RECORD;
	m_rec_new_pscustomers				RECORD;
	sales_count    integer := (SELECT COUNT (*) FROM sales);
	m_next_sales_id	 integer := sales_count + 1;
	m_state_id	 integer;
	m_category_id integer;
BEGIN
	RAISE NOTICE 'Begin execute_trigger_test';

	random_uid = mod ((round (random () * uid_count))::int, uid_count) + 1;
	random_pid = mod ((round (random () * pid_count))::int, pid_count) + 1;
	random_qty = round (random () * 5) + 1;
	totalprice =
              random_qty *
             (SELECT p.listprice
               FROM products AS p
               WHERE p.id = random_pid);
	RAISE NOTICE 'random_uid=%; random_pid=%; random_qty=%; totalprice=%', random_uid, random_pid, random_qty, totalprice;

	-- Populate necessary variables
	RAISE NOTICE 'Fetch fields from snowflake relations';
	SELECT st.id INTO m_state_id
	FROM users u
	INNER JOIN states st on u.state=st.id
	WHERE u.id=random_uid;
	RAISE NOTICE 'm_state_id=%', m_state_id;

	SELECT c.id INTO m_category_id
	FROM categories c
	INNER JOIN products p ON c.id=p.cid
	WHERE p.id=random_pid;
	RAISE NOTICE 'm_category_id=%', m_category_id;

	RAISE NOTICE 'Fetch previous records for comparison';
	SELECT category_id, state_id, category_name, state_name, quantity_sold, dollar_value INTO m_rec_prev_pcategory_state
    FROM pcategory_state
    WHERE state_id=m_state_id AND category_id=m_category_id;
    RAISE NOTICE 'm_rec_prev_pcategory_state=%', m_rec_prev_pcategory_state;

    SELECT id, category_name, quantity_sold, dollar_value INTO m_rec_prev_pcategory
  	FROM pcategory
  	WHERE id=m_category_id;
  	RAISE NOTICE 'm_rec_prev_pcategory=%', m_rec_prev_pcategory;

  	SELECT customer_id, product_id, customer_name, product_sku, quantity_sold, dollar_value INTO m_rec_prev_pcustomer_product
  	FROM pcustomer_product
  	WHERE customer_id=random_uid AND product_id=random_pid;
  	RAISE NOTICE 'm_rec_prev_pcustomer_product=%', m_rec_prev_pcustomer_product;

  	SELECT id, state_name, quantity_sold, dollar_value INTO m_rec_prev_pstate
  	FROM pstate
  	WHERE id=m_state_id;
  	RAISE NOTICE 'm_rec_prev_pstate=%', m_rec_prev_pstate;

	RAISE NOTICE 'Executing insertion using uid=%; pid=%; qty=%; price=%', random_uid, random_pid, random_qty, totalprice;
	INSERT INTO sales (id, uid,
                    pid,
                    quantity,
                    price)
	VALUES (m_next_sales_id, random_uid,
              random_pid,
              random_qty,
              totalprice);

	RAISE NOTICE 'Fetch current records for comparison';
	SELECT category_id, state_id, category_name, state_name, quantity_sold, dollar_value INTO m_rec_new_pcategory_state
	FROM pcategory_state
	WHERE state_id=m_state_id AND category_id=m_category_id;
	RAISE NOTICE 'm_rec_new_pcategory_state=%', m_rec_new_pcategory_state;
	IF m_rec_new_pcategory_state.quantity_sold = m_rec_prev_pcategory_state.quantity_sold OR m_rec_new_pcategory_state.dollar_value = m_rec_prev_pcategory_state.dollar_value THEN
		RAISE EXCEPTION 'm_rec_new_pcategory_state was not updated';
	END IF;

	SELECT id, category_name, quantity_sold, dollar_value INTO m_rec_new_pcategory
  	FROM pcategory
  	WHERE id=m_category_id;
  	RAISE NOTICE 'm_rec_new_pcategory=%', m_rec_new_pcategory;
  	IF m_rec_new_pcategory.quantity_sold = m_rec_prev_pcategory.quantity_sold OR m_rec_new_pcategory.dollar_value = m_rec_prev_pcategory.dollar_value THEN
		RAISE EXCEPTION 'm_rec_new_pcategory was not updated';
	END IF;

  	SELECT customer_id, product_id, customer_name, product_sku, quantity_sold, dollar_value INTO m_rec_new_pcustomer_product
  	FROM pcustomer_product
  	WHERE customer_id=random_uid AND product_id=random_pid;
  	RAISE NOTICE 'm_rec_new_pcustomer_product=%', m_rec_new_pcustomer_product;
  	IF m_rec_new_pcustomer_product.quantity_sold = m_rec_prev_pcustomer_product.quantity_sold OR m_rec_new_pcustomer_product.dollar_value = m_rec_prev_pcustomer_product.dollar_value THEN
		RAISE EXCEPTION 'm_rec_new_pcustomer_product was not updated';
	END IF;

  	SELECT id, state_name, quantity_sold, dollar_value INTO m_rec_new_pstate
  	FROM pstate
  	WHERE id=m_state_id;
  	RAISE NOTICE 'm_rec_new_pstate=%', m_rec_new_pstate;
  	IF m_rec_new_pstate.quantity_sold = m_rec_prev_pstate.quantity_sold OR m_rec_new_pstate.dollar_value = m_rec_prev_pstate.dollar_value THEN
		RAISE EXCEPTION 'm_rec_new_pstate was not updated';
	END IF;

END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
ALTER FUNCTION execute_trigger_test()
  OWNER TO dyerke;