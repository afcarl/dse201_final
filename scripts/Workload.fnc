CREATE OR REPLACE FUNCTION Transactions ()
   RETURNS void
AS
   $$
   DECLARE
      random_uid   integer := 0;
      uid_count    integer := (SELECT COUNT (*) FROM users);
      random_pid   integer := 0;
      pid_count    integer := (SELECT COUNT (*) FROM products);
      random_qty   integer := 0;
      totalprice   integer := 0;
      i            integer := 0;
   BEGIN
      random_uid := mod ((round (random () * uid_count))::int, uid_count) + 1;

      FOR i IN 1 .. 10
      LOOP
         random_pid = mod ((round (random () * pid_count))::int, pid_count) + 1;
         random_qty = round (random () * 5) + 1;
         totalprice =
              random_qty
            * (SELECT p.listprice
               FROM products AS p
               WHERE p.id = random_pid);
         INSERT INTO sales (uid,
                            pid,
                            quantity,
                            price)
              VALUES (random_uid,
                      random_pid,
                      random_qty,
                      totalprice);
      -- Add triggers here to update precomputed tables.
      
      END LOOP;
   END;
   $$
   LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION Workload (num_iterations integer)
   RETURNS void
AS
   $$
   DECLARE
      i           integer := 0;
      j           integer := 0;
      StartTime   timestamptz;
      EndTime     timestamptz;
      Delta       integer := 0;
   BEGIN
      StartTime := clock_timestamp ();

      FOR i IN 1 .. num_iterations
      LOOP
         -- Add 1000 carts of ten items each
         FOR j IN 1 .. 1000
         LOOP
            PERFORM Transactions();
         END LOOP;

      -- Queries

      -- 1.   Show the total sales (quantity sold and dollar value) for each customer.

      -- 2.   Show the total sales for each state.

      -- 3.   Show the total sales for each product, for a given customer. Only products
      --      that were actually bought by the given customer. Order by dollar value.

      -- 4.   Show the total sales for each product and customer. Order by dollar value.

      -- 5.   Show the total sales for each product category and state.
      END LOOP;

      EndTime := clock_timestamp ();
      Delta :=
         round (
              1000
            * (extract (EPOCH FROM EndTime) - extract (EPOCH FROM StartTime))
            / num_iterations);
      RAISE NOTICE 'Duration in millisecs=%' , Delta;
   END;
   $$
   LANGUAGE plpgsql;