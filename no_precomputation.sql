-- Show the total sales (quantity sold and dollar value) for each customer (name).
SELECT users.name, sum(sales.quantity) as quantity_total, sum(sales.price) as price_total
FROM users, sales
WHERE users.id = sales.uid
GROUP BY users.name

-- Show the total sales for each state.
SELECT states.name, sum(sales.quantity) as quantity_total, sum(sales.price) as price_total
FROM sales, users, states
WHERE sales.uid = users.id AND 
	users.state = states.id
GROUP BY states.name

-- Show the total sales for each product, for a given customer.
-- Only products that were actually bought by the given customer.
-- Order by dollar value.
-- The example below only shows querying for one user.
SELECT products.sku as product_sku, sum(sales.quantity) as total_quantity, sum(sales.price) as total_price
FROM sales, products, users
WHERE 	users.name = 'user_1' AND 
	sales.uid = users.id AND 
	products.id = sales.pid
GROUP BY products.sku
ORDER BY total_price

-- Show the total sales for each product and customer.
-- Order by dollar value
SELECT products.sku as product_sku, users.name as customer, sum(sales.quantity) as total_quantity, sum(sales.price) as total_price
FROM sales, products, users
WHERE sales.uid = users.id AND 
	products.id = sales.pid
GROUP BY products.sku, users.name
ORDER BY total_price

-- Show the total sales for each product category and state.
SELECT states.name as state_name, categories.name as category_name, sum(sales.quantity) as total_quantity, sum(sales.price) as total_price
FROM sales, products, users, categories, states
WHERE sales.uid = users.id AND
	users.state = states.id AND
	products.id = sales.pid AND
	categories.id = products.cid
GROUP BY states.name, categories.name
