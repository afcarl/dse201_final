CREATE INDEX sales_uid_idx ON sales USING hash (uid);
CREATE INDEX sales_pid_idx ON sales USING hash (pid);

CREATE INDEX users_state_idx ON users USING hash (state);

CREATE INDEX products_cid_idx ON products USING hash (cid);
