CREATE OR REPLACE FUNCTION generate_states ()
   RETURNS void
AS
   $$
   DECLARE
      states   text []
         := '{  "Alabama", "Alaska", "Arizona", "Arkansas", "California", "Colorado", "Connecticut",
            "Delaware", "Florida", "Georgia", "Hawaii", "Idaho", "Illinois", "Indiana", "Iowa", "Kansas",
            "Kentucky", "Louisiana", "Maine", "Maryland", "Massachusetts", "Michigan", "Minnesota", "Mississippi",
            "Missouri", "Montana", "Nebraska", "Nevada", "New Hampshire", "New Jersey", "New Mexico", "New York",
            "North Carolina", "North Dakota", "Ohio", "Oklahoma", "Oregon", "Pennsylvania", "Rhode Island",
            "South Carolina", "South Dakota", "Tennessee", "Texas", "Utah", "Vermont", "Virginia", "Washington",
            "West Virginia", "Wisconsin", "Wyoming" }';
      i        integer := 0;
   BEGIN
      FOR i IN 1 .. 50
      LOOP
         INSERT INTO states (name)
              VALUES (states[i]);
      END LOOP;
   END;
   $$
   LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION generate_users (num_users integer)
   RETURNS void
AS
   $$
   DECLARE
      i        integer := 0;
   BEGIN
      FOR i IN 1 .. num_users
      LOOP
         INSERT INTO users (name,
                            state)
              VALUES (
                'user_' || i,
                1 + mod( round (random () * 50)::int, 50)
              );
      END LOOP;
   END;
   $$
   LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION generate_categories ( num_categories integer )
   RETURNS void
AS
   $$
   DECLARE
      i   integer := 0;
   BEGIN
      FOR i IN 1 .. num_categories
      LOOP
         INSERT INTO categories (name, description)
                 VALUES (
                    'category_' || i,
                    'A very useful description...'
                 );
      END LOOP;
   END;
   $$
   LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION generate_products_and_sales (
    num_users         integer,
    num_products      integer,
    num_categories    integer
)
   RETURNS void
AS
   $$
   DECLARE
      i   integer := 0;
      j   integer := 0;
   BEGIN
      FOR i IN 1 .. num_products
      LOOP
         DECLARE
             price integer := round (random () * 1000);
         BEGIN
             INSERT INTO products (cid, name, SKU, listprice)
                     VALUES (
                       1 + mod ( round (random () * num_categories)::int , num_categories),
                       'product_' || i,
                       'SKU_' || i,
                       price
                     );
             FOR j in 1 .. 100
             LOOP
                 DECLARE
                     quant integer := 1 + round (random () * 4); 
                 BEGIN
                     INSERT INTO sales (uid, pid, quantity, price)
                     VALUES (
                        1 + mod (round (random() * num_users)::int, num_users),
                        i,
                        quant,
                        quant * price
                     );
                END;
             END LOOP;
         END;
      END LOOP;
   END;
   $$
   LANGUAGE plpgsql;



CREATE OR REPLACE FUNCTION DataGenerator (number_of_sales integer)
   RETURNS void
AS
   $$
   DECLARE
      -- Generate other values from number of sales.
      number_of_users        integer := number_of_sales / 10;
      number_of_products     integer := number_of_sales / 100;
      number_of_categories   integer := number_of_products / 10;
   BEGIN
    -- Replace tables
    RAISE NOTICE 'Replacing tables...';
    DROP TABLE IF EXISTS states CASCADE;
    CREATE TABLE states (
        id SERIAL PRIMARY KEY,
        name TEXT NOT NULL UNIQUE
    );
    DROP TABLE IF EXISTS users CASCADE;
    CREATE TABLE users (
        id SERIAL PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        state INTEGER REFERENCES states(id)
    );
    DROP TABLE IF EXISTS categories CASCADE;
    CREATE TABLE categories(
        id SERIAL PRIMARY KEY,
        name TEXT NOT NULL UNIQUE,
        description TEXT
    );
    DROP TABLE IF EXISTS products CASCADE;
    CREATE TABLE products (
        id SERIAL PRIMARY KEY,
        cid INTEGER REFERENCES categories (id) ON DELETE CASCADE,
        name TEXT NOT NULL,
        SKU TEXT NOT NULL UNIQUE,
        listprice INTEGER NOT NULL
    );
    DROP TABLE IF EXISTS sales CASCADE;
    CREATE TABLE sales (
        id SERIAL PRIMARY KEY,
        uid INTEGER REFERENCES users (id) ON DELETE CASCADE,
        pid INTEGER REFERENCES products (id) ON DELETE CASCADE,
        quantity INTEGER NOT NULL,
        price INTEGER NOT NULL
    );
    RAISE NOTICE 'Now generating data...';
    PERFORM generate_states();
    RAISE NOTICE '50 States added...';
    PERFORM generate_users(number_of_users);
    RAISE NOTICE '% Users added...', number_of_users;
    PERFORM generate_categories(number_of_categories);
    RAISE NOTICE '% Categories added...', number_of_categories;
    PERFORM generate_products_and_sales(
        number_of_users,
        number_of_products,
        number_of_categories
    );
    RAISE NOTICE '% Products added...', number_of_products;
    RAISE NOTICE '% Sales added...', number_of_sales;
END;
$$
LANGUAGE plpgsql;

SELECT DataGenerator (10000);
SELECT * FROM states LIMIT 10;
SELECT * FROM users LIMIT 10;
SELECT * FROM products LIMIT 10;
SELECT * FROM categories LIMIT 10;
SELECT * FROM sales LIMIT 10;
