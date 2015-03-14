-- TRIGGER FOR precomputed table pcategory_state
DROP TRIGGER IF EXISTS t_update_pcategory_state on sales;

CREATE OR REPLACE FUNCTION update_pcategory_state()
  RETURNS trigger AS
$BODY$
DECLARE
	m_category_id integer;
	m_category_name text;
	m_state_id integer;
	m_state_name text;
BEGIN
	
	-- Insert or update the summary row with the new values.
	SELECT c.id, c.name INTO m_category_id, m_category_name
	FROM categories c
	INNER JOIN products p ON c.id=p.cid
	WHERE p.id=NEW.pid;

	SELECT st.id, st.name INTO m_state_id, m_state_name
	FROM users u
	INNER JOIN states st on u.state=st.id
	WHERE u.id=NEW.uid;

    UPDATE pcategory_state 
	SET quantity_sold=quantity_sold + NEW.quantity, dollar_value= dollar_value + NEW.price
	WHERE category_id= m_category_id AND state_id= m_state_id;

	IF NOT FOUND THEN
	    INSERT INTO pcategory_state(
            category_id, state_id, category_name, state_name, quantity_sold, 
            dollar_value)
	    VALUES (m_category_id, m_state_id, m_category_name, m_state_name, NEW.quantity, 
	            NEW.price);
	END IF;
	
	RETURN NULL;
END;
$BODY$ LANGUAGE plpgsql;

CREATE TRIGGER t_update_pcategory_state AFTER INSERT 
   ON sales FOR EACH ROW
   EXECUTE PROCEDURE public.update_pcategory_state();

-- TRIGGER FOR precomputed table pstate
DROP TRIGGER IF EXISTS t_update_pstate on sales;

CREATE OR REPLACE FUNCTION update_pstate()
  RETURNS trigger AS
$BODY$
DECLARE
	m_state_id	integer;
	m_state_name	text;
BEGIN

	SELECT st.id, st.name INTO m_state_id, m_state_name
	FROM users u
	INNER JOIN states st on u.state=st.id
	WHERE u.id=NEW.uid;

	UPDATE pstate 
	SET quantity_sold=quantity_sold + NEW.quantity, dollar_value= dollar_value + NEW.price
	WHERE id=m_state_id;
	
	IF NOT FOUND THEN
		INSERT INTO pstate(id, name, quantity_sold, dollar_value)
		VALUES (m_state_id, m_state_name, NEW.quantity, NEW.price);
	END IF;
	
	RETURN NULL;
END;
$BODY$ LANGUAGE plpgsql;

CREATE TRIGGER t_update_pstate AFTER INSERT 
   ON sales FOR EACH ROW
   EXECUTE PROCEDURE public.update_pstate();

-- TRIGGER FOR precomputed table pcustomer
CREATE OR REPLACE FUNCTION pcustomer_trigger_f() 
	RETURNS TRIGGER AS $BODY$
    BEGIN
		UPDATE 	pcustomer
		SET 	quantity_sold = quantity_sold + NEW.quantity,
				dollar_value = dollar_value + NEW.price
		WHERE 	id = NEW.uid;
	
		IF NOT FOUND THEN
			INSERT INTO pcustomer(id, name, quantity_sold, dollar_value)
			SELECT id, name, NEW.quantity, NEW.price
			FROM users u
			WHERE u.id = NEW.uid;
		END IF;
		
		RETURN NULL;
	END;
$BODY$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS pcustomer_trigger ON sales;

CREATE TRIGGER pcustomer_trigger
AFTER INSERT ON sales
    FOR EACH ROW EXECUTE PROCEDURE pcustomer_trigger_f();

-- TRIGGER FOR precomputed table pcustomer_product
CREATE OR REPLACE FUNCTION pcustomer_product_trigger_f() 
	RETURNS TRIGGER AS $BODY$
	DECLARE
		m_customer_id	integer;
		m_customer_name	text;
		m_product_id	integer;
		m_product_name	text;
    BEGIN
    
		-- Insert or update the summary row with the new values.
		SELECT p.id, p.name INTO m_product_id, m_product_name
		FROM products p
		WHERE p.id=NEW.pid;

		SELECT u.id, u.name INTO m_customer_id, m_customer_name
		FROM users u
		WHERE u.id=NEW.uid;
    
		UPDATE 	pcustomer_product
		SET 	quantity_sold = quantity_sold + NEW.quantity,
				dollar_value = dollar_value + NEW.price
		WHERE 	customer_id = m_customer_id AND
				product_id = m_product_id;
		IF NOT FOUND THEN
			INSERT INTO pcustomer_product(customer_id, customer_name, product_id, product_name, quantity_sold, dollar_value)
			VALUES (m_customer_id, m_customer_name, m_product_id, m_product_name, NEW.quantity, NEW.price);
		END IF;
		RETURN NULL;
	END;
$BODY$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS pcustomer_product_trigger ON sales;

CREATE TRIGGER pcustomer_product_trigger
AFTER INSERT ON sales
    FOR EACH ROW EXECUTE PROCEDURE pcustomer_product_trigger_f();
    
-- TRIGGER FOR precomputed table pcategory
CREATE OR REPLACE FUNCTION pcategory_trigger_f() 
	RETURNS TRIGGER AS $BODY$
	DECLARE
		m_category_id	integer;
		m_category_name	text;
	BEGIN
		-- Insert or update the summary row with the new values.
		SELECT c.id, c.name INTO m_category_id, m_category_name
		FROM categories c
		INNER JOIN products p ON c.id=p.cid
		WHERE p.id=NEW.pid;
		
		UPDATE 	pcategory
		SET 	quantity_sold = quantity_sold + NEW.quantity,
				dollar_value = dollar_value + NEW.price
		WHERE id = m_category_id;
		
		IF NOT found THEN
			INSERT INTO pcategory (id, category_name, quantity_sold, dollar_value)
			VALUES (m_category_id, m_category_name, NEW.quantity, NEW.price);
		END IF;
		RETURN NULL;
	END;
$BODY$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS pcategory_trigger ON sales;

CREATE TRIGGER pcategory_trigger
AFTER INSERT ON sales
    FOR EACH ROW EXECUTE PROCEDURE pcategory_trigger_f();

