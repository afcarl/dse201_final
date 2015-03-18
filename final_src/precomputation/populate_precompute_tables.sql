-- INSERT INTO CUSTOMER_PRODUCT and CUSTOMERS
INSERT INTO pcustomer_product
SELECT u.id as customer_id, p.id as product_id, u.name as customer_name, p.sku as product_sku, sum(s.quantity) as quantity_sold, sum(s.price) as dollar_value
FROM sales s
INNER JOIN users u on s.uid=u.id
INNER JOIN products p on s.pid=p.id
GROUP BY u.id, p.id, u.name, p.sku;

-- roll pcustomer_product into pcustomer
INSERT INTO pcustomer
SELECT customer_id, customer_name, sum(quantity_sold) as quantity_sold, sum(dollar_value) as dollar_value
FROM pcustomer_product
GROUP BY customer_id, customer_name;

-- INSERT INTO PCATEGORY_STATE, STATE, CATEGORY
INSERT INTO pcategory_state
SELECT c.id as category_id, st.id as state_id, c.name as category_name, st.name as state_name, sum(sl.quantity) as quantity_sold, sum(sl.price) as dollar_value
FROM sales sl
INNER JOIN users u ON sl.uid = u.id
INNER JOIN states st ON u.state = st.id
INNER JOIN products p ON p.id = sl.pid
INNER JOIN categories c ON c.id = p.cid
GROUP BY c.id, c.name, st.id, st.name;

-- roll pcategory_state into pstate
INSERT INTO pstate
SELECT state_id, state_name, sum(quantity_sold) as quantity_sold, sum(dollar_value) as dollar_value
FROM pcategory_state
GROUP BY state_id, state_name;

-- roll pcategory_state into pcategory
INSERT INTO pcategory
SELECT category_id, category_name, sum(quantity_sold) as quantity_sold, sum(dollar_value) as dollar_value
FROM pcategory_state
GROUP BY category_id, category_name;