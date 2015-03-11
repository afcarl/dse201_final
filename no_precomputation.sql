-- Show the total sales (quantity sold and dollar value) for each customer (name).
SELECT users.name as customer_name, sum(sales.quantity) as quantity_sold, sum(sales.price) as dollar_value
FROM users, sales 
WHERE users.id = sales.uid
GROUP BY users.name

-- Show the total sales for each state.
SELECT states.name as state_name, sum(sales.quantity) as quantity_sold, sum(sales.price) as dollar_value
FROM sales, users, states
WHERE sales.uid = users.id AND 
	users.state = states.id
GROUP BY states.name

-- Show the total sales for each product, for a given customer.
-- Only products that were actually bought by the given customer.
-- Order by dollar value.
-- The example below only shows querying for one user.
SELECT products.sku as product_sku, sum(sales.quantity) as quantity_sold, sum(sales.price) as dollar_value
FROM sales, products, users
WHERE 	users.name = 'user_1' AND 
	sales.uid = users.id AND 
	products.id = sales.pid
GROUP BY products.sku
ORDER BY dollar_value

-- Show the total sales for each product and customer.
-- Order by dollar value
SELECT products.sku as product_sku, users.name as customer, sum(sales.quantity) as quantity_sold, sum(sales.price) as dollar_value
FROM sales, products, users
WHERE sales.uid = users.id AND 
	products.id = sales.pid
GROUP BY products.sku, users.name
ORDER BY dollar_value

-- Show the total sales for each product category and state.
SELECT states.name as state_name, categories.name as category_name, sum(sales.quantity) as total_quantity, sum(sales.price) as dollar_value
FROM sales, products, users, categories, states
WHERE sales.uid = users.id AND
	users.state = states.id AND
	products.id = sales.pid AND
	categories.id = products.cid
GROUP BY states.name, categories.name

-- top 20 categories and customers
with top_20_categories as (
select c.id as category_id, c.name as category_name, sum(s.quantity) as quantity_sold, sum(s.price) as dollar_value
from sales as s
inner join products as p on s.pid=p.id
inner join categories as c on p.cid=c.id
group by c.id, c.name
order by dollar_value desc
limit 20
), top_20_customers as (
select u.id as customer_id, u.name as customer_name, sum(s.quantity) as quantity_sold, sum(s.price) as dollar_value
from sales as s
inner join users as u on s.uid=u.id
group by u.id, u.name
order by dollar_value desc
limit 20
)
select tcat.category_name as top_category, tc.customer_name as top_customer, sum(s.quantity) as quantity_sold, sum(s.price) as dollar_value
from sales s
inner join products as p on s.pid=p.id
inner join top_20_categories as tcat on p.cid=tcat.category_id
inner join top_20_customers as tc on s.uid=tc.customer_id
group by tcat.category_name, tc.customer_name
order by dollar_value desc
