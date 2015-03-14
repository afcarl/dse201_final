-- TRIGGER FOR precomputed table pcustomer
CREATE OR REPLACE FUNCTION pcustomer_trigger_f() 
	RETURNS TRIGGER AS $BODY$
    BEGIN
		UPDATE 	pcustomer
		SET 	quantity_sold = quantity_sold + NEW.quantity,
				dollar_value = dollar_value + NEW.price
		WHERE 	id = NEW.uid;
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
    BEGIN
		UPDATE 	pcustomer_product
		SET 	quantity_sold = quantity_sold + NEW.quantity,
				dollar_value = dollar_value + NEW.price
		WHERE 	customer_id = NEW.uid AND
				product_id = NEW.pid;
		RETURN NULL;
	END;
$BODY$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS pcustomer_product_trigger ON sales;

CREATE TRIGGER pcustomer_product_trigger
AFTER INSERT ON sales
    FOR EACH ROW EXECUTE PROCEDURE pcustomer_product_trigger_f();
