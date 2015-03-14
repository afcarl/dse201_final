-- STATES
DROP TABLE IF EXISTS pstate;

CREATE TABLE pstate
(
  id serial NOT NULL,
  state_name text NOT NULL,
  quantity_sold integer NOT NULL,
  dollar_value integer NOT NULL,
  CONSTRAINT pstate_pkey PRIMARY KEY (id),
  CONSTRAINT pstate_name_key UNIQUE (state_name)
);

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