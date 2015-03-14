CREATE OR REPLACE FUNCTION do_insert_compare(random_uid integer, random_pid integer, random_qty integer)
  RETURNS void AS
$BODY$
DECLARE
	totalprice   integer := 0;
	m_rec_prev_pcategory_state			RECORD;
	m_rec_prev_pcategory	 			RECORD;
	m_rec_prev_pcustomer_product		RECORD;
	m_rec_prev_pstate					RECORD;
	m_rec_prev_pcustomer				RECORD;
	m_rec_new_pcategory_state			RECORD;
	m_rec_new_pcategory	 				RECORD;
	m_rec_new_pcustomer_product			RECORD;
	m_rec_new_pstate					RECORD;
	m_rec_new_pcustomer				RECORD;
	sales_count    integer := (SELECT COUNT (*) FROM sales);
	m_next_sales_id	 integer := sales_count + 1;
	m_state_id	 integer;
	m_category_id integer;
	-- new records
	
BEGIN
	RAISE NOTICE 'Begin do_insert_compare';

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
	SELECT id, customer_name, quantity_sold, dollar_value INTO m_rec_prev_pcustomer
	FROM pcustomer
	WHERE id=random_uid;
	RAISE NOTICE 'm_rec_prev_pcustomer=%', m_rec_prev_pcustomer;
	
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
	SELECT id, customer_name, quantity_sold, dollar_value INTO m_rec_new_pcustomer
	FROM pcustomer
	WHERE id=random_uid;
	RAISE NOTICE 'm_rec_new_pcustomer=%', m_rec_new_pcustomer;
	IF m_rec_new_pcustomer.quantity_sold = m_rec_prev_pcustomer.quantity_sold OR m_rec_new_pcustomer.dollar_value = m_rec_prev_pcustomer.dollar_value THEN
		RAISE EXCEPTION 'm_rec_new_pcustomer was not updated';
	END IF;
	
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

CREATE OR REPLACE FUNCTION execute_trigger_update_test()
  RETURNS void AS
$BODY$
DECLARE
	random_uid   integer := 0;
	uid_count    integer := (SELECT COUNT (*) FROM users);
	random_pid   integer := 0;
	pid_count    integer := (SELECT COUNT (*) FROM products);
	random_qty   integer := 0;
BEGIN
	RAISE NOTICE 'Begin execute_trigger_update_test';

	random_uid = mod ((round (random () * uid_count))::int, uid_count) + 1;
	random_pid = mod ((round (random () * pid_count))::int, pid_count) + 1;
	random_qty = round (random () * 5) + 1;

	PERFORM do_insert_compare(random_uid, random_pid, random_qty);

END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION execute_trigger_insert_test()
  RETURNS void AS
$BODY$
DECLARE
	-- new state
	new_state_id   	integer;
	new_state_name   text;
	-- new user
	new_user_id   	integer;
	new_user_name   text;
	-- new category
	new_cat_id   		  integer;
	new_cat_name   		  text;
	new_cat_description   text;
	-- new product
	new_prod_id   		    integer;
	new_prod_name   		text;
	new_prod_sku   			text;
	new_prod_listprice 		integer := round (random () * 1000);
	random_qty   			integer := 0;
BEGIN
	RAISE NOTICE 'Begin execute_trigger_insert_test';

	SELECT max(id) FROM states INTO new_state_id;
	new_state_id= new_state_id + 1;
	new_state_name = 'NewState' || new_state_id;
	RAISE NOTICE 'Executing insertion using new_state_id=%; new_state_name=%', new_state_id, new_state_name;
	INSERT INTO states(id, name) VALUES (new_state_id, new_state_name);

	SELECT max(id) FROM users INTO new_user_id;
	new_user_id= new_user_id + 1;
	new_user_name = 'NewUser' || new_user_id;
	RAISE NOTICE 'Executing insertion using new_user_id=%; new_user_name=%', new_user_id, new_user_name;
	INSERT INTO users(id, name, state) VALUES (new_user_id, new_user_name, new_state_id);

	SELECT max(id) FROM categories INTO new_cat_id;
	new_cat_id= new_cat_id + 1;
	new_cat_name = 'NewCategory' || new_cat_id;
	new_cat_description = 'Description of ' || new_cat_name;
	RAISE NOTICE 'Executing insertion using new_cat_id=%; new_cat_name=%; new_cat_description=%', new_cat_id, new_cat_name, new_cat_description;
	INSERT INTO categories(id, name, description) VALUES (new_cat_id, new_cat_name, new_cat_description);

	SELECT max(id) FROM products INTO new_prod_id;
	new_prod_id= new_prod_id + 1;
	new_prod_name = 'NewProduct' || new_prod_id;
	new_prod_sku = 'SQU1234' || new_prod_name;
	RAISE NOTICE 'Executing insertion using new_prod_id=%; new_prod_name=%; new_prod_sku=%', new_prod_id, new_prod_name, new_prod_sku;
	INSERT INTO products(id, cid, name, sku, listprice) VALUES (new_prod_id, new_cat_id, new_prod_name, new_prod_sku, new_prod_listprice);

	random_qty = round (random () * 5) + 1;

	PERFORM do_insert_compare(new_user_id, new_prod_id, random_qty);

END;$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;