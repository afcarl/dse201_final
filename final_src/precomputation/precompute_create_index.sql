CREATE INDEX pcustomer_product_cust_name_idx ON pcustomer_product (customer_name);
CREATE INDEX sales_pid_idx ON sales (pid);
CREATE INDEX sales_uid_idx ON sales (uid);
CREATE INDEX products_cid_idx ON products (cid);

CREATE INDEX pcustomer_dollar_value_desc_index ON pcustomer (dollar_value DESC);
CREATE INDEX pcategory_dollar_value_desc_index ON pcategory (dollar_value DESC);
