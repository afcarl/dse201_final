-- STATES
DROP TABLE IF EXISTS pstates;

CREATE TABLE pstates
(
  id serial NOT NULL,
  state_name text NOT NULL,
  quantity_sold integer NOT NULL,
  dollar_value integer NOT NULL,
  CONSTRAINT pstates_pkey PRIMARY KEY (id),
  CONSTRAINT pstates_name_key UNIQUE (state_name)
);
/*
INSERT INTO pstates
SELECT states.id, states.name as state_name, sum(sales.quantity) as quantity_sold, sum(sales.price) as dollar_value
FROM sales, users, states
WHERE sales.uid = users.id AND
        users.state = states.id
GROUP BY states.id, states.name;
*/

-- CUSTOMER
DROP TABLE IF EXISTS pcustomer;

CREATE TABLE pcustomer
(
  id serial NOT NULL,
  customer_name text NOT NULL,
  quantity_sold integer NOT NULL,
  dollar_value integer NOT NULL,
  CONSTRAINT pcustomer_pkey PRIMARY KEY (id),
  CONSTRAINT pcustomer_name_key UNIQUE (customer_name)
);
/*
INSERT INTO pcustomer
SELECT u.id as id, u.name as customer_name, sum(s.quantity) as quantity_sold, sum(s.price) as dollar_value
FROM sales s
INNER JOIN users u on s.uid=u.id
GROUP BY u.id, u.name;
*/

-- CATEGORY
DROP TABLE IF EXISTS pcategory;

CREATE TABLE pcategory
(
  id serial NOT NULL,
  category_name text NOT NULL,
  quantity_sold integer NOT NULL,
  dollar_value integer NOT NULL,
  CONSTRAINT pcategory_pkey PRIMARY KEY (id),
  CONSTRAINT pcategory_name_key UNIQUE (category_name)
);
/*
INSERT INTO pcategory
SELECT c.id as id, c.name as category_name, sum(s.quantity) as quantity_sold, sum(s.price) as dollar_value
FROM sales s
INNER JOIN products p on s.pid=p.id
INNER JOIN categories c on p.cid = c.id
GROUP BY c.id, c.name;
*/

-- CUSTOMER_PRODUCT
DROP TABLE IF EXISTS pcustomer_product;

CREATE TABLE pcustomer_product
(
  customer_id serial NOT NULL,
  product_id serial NOT NULL,
  customer_name text NOT NULL,
  product_sku text NOT NULL,
  quantity_sold integer NOT NULL,
  dollar_value integer NOT NULL,
  CONSTRAINT pcustomer_product_pkey PRIMARY KEY (customer_id,product_id)
);

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

-- CATEGORY_STATE
DROP TABLE IF EXISTS pcategory_state;

CREATE TABLE pcategory_state
(
  category_id serial NOT NULL,
  state_id serial NOT NULL,
  category_name text NOT NULL,
  state_name text NOT NULL,
  quantity_sold integer NOT NULL,
  dollar_value integer NOT NULL,
  CONSTRAINT pcategory_state_pkey PRIMARY KEY (category_id, state_id)
);

INSERT INTO pcategory_state
SELECT c.id as category_id, st.id as state_id, c.name as category_name, st.name as state_name, sum(sl.quantity) as quantity_sold, sum(sl.price) as dollar_value
FROM sales sl
INNER JOIN users u ON sl.uid = u.id
INNER JOIN states st ON u.state = st.id
INNER JOIN products p ON p.id = sl.pid
INNER JOIN categories c ON c.id = p.cid
GROUP BY c.id, c.name, st.id, st.name;

-- roll pcategory_state into pcategory
INSERT INTO pcategory
SELECT category_id, category_name, sum(quantity_sold) as quantity_sold, sum(dollar_value) as dollar_value
FROM pcategory_state
GROUP BY category_id, category_name;

-- roll pcategory_state into pstates
INSERT INTO pstates
SELECT state_id, state_name, sum(quantity_sold) as quantity_sold, sum(dollar_value) as dollar_value
FROM pcategory_state
GROUP BY state_id, state_name;
