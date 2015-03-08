-- Show the total sales (quantity sold and dollar value) for each customer (name).
SELECT users.name, sum(sales.quantity) as quantity_total, sum(sales.price) as price_total
FROM users, sales
WHERE users.id = sales.uid
GROUP BY sales.uid, users.name

-- Show the total sales for each state.
SELECT states.name, sum(sales.quantity), sum(sales.price)
FROM sales, users, states
WHERE sales.uid = users.id AND users.state = states.id
GROUP BY states.name

-- Show the total sales for each product, for a given customer.
-- Only products that were actually bought by the given customer.
-- Order by dollar value.

-- Show the total sales for each product and customer.
-- Order by dollar value

-- Show the total sales for each product category and state.
