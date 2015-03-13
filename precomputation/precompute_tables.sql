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

INSERT INTO pstates
SELECT states.id, states.name as state_name, sum(sales.quantity) as quantity_sold, sum(sales.price) as dollar_value
FROM sales, users, states
WHERE sales.uid = users.id AND
        users.state = states.id
GROUP BY states.id, states.name;

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

INSERT INTO pcustomer
SELECT u.id as id, u.name as customer_name, sum(s.quantity) as quantity_sold, sum(s.price) as dollar_value
FROM sales s
INNER JOIN users u on s.uid=u.id
GROUP BY u.id, u.name

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
GROUP BY u.id, p.id, u.name, p.sku
