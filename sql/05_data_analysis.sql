-- Data Analysis

SELECT * from olist.orders limit 10;

SELECT *  from olist.products_clean limit 10;

SELECT * from olist.order_items limit 10;

SELECT * from olist.customers limit 10;

SELECT * from olist.order_reviews_clean limit 10;

SELECT * from olist.category_translation;


-- --------------------------------------------------------------------------------------------------------
-- Total Price of each order
-- --------------------------------------------------------------------------------------------------------
SELECT order_id, sum(price) as order_price, sum(freight_value) as order_freight, sum(price) + sum(freight_value) as total_amount
FROM order_items
GROUP BY order_id
;

-- --------------------------------------------------------------------------------------------------------
-- 1.Monthly Sales
-- --------------------------------------------------------------------------------------------------------

SELECT year(o.order_purchase_timestamp), month(o.order_purchase_timestamp), count(DISTINCT o.order_id) as number_of_monthly_orders, sum(i.price) + sum(i.freight_value) as monthly_sells
FROM order_items as i
JOIN orders as o ON i.order_id = o.order_id
WHERE o.order_purchase_timestamp >= '2017-01-01' AND o.order_purchase_timestamp < '2018-09-01' AND o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY  year(o.order_purchase_timestamp), month(o.order_purchase_timestamp)
ORDER BY year(o.order_purchase_timestamp), month(o.order_purchase_timestamp)
;

-- --------------------------------------------------------------------------------------------------------
-- 2.Sales in each product category
-- --------------------------------------------------------------------------------------------------------
SELECT COALESCE(c.product_category_name_english, p.product_category_name, 'unknown') AS category, 
sum(i.price) as category_revenue,
round(sum(i.price) / sum(sum(i.price)) OVER() * 100, 2) as percentage
FROM orders as o
JOIN order_items as i ON i.order_id = o.order_id
LEFT JOIN products_clean as p ON i.product_id = p.product_id
LEFT JOIN category_translation as c ON p.product_category_name = c.product_category_name
WHERE o.order_purchase_timestamp >= '2017-01-01' AND o.order_purchase_timestamp < '2018-09-01' AND o.order_status NOT IN ('canceled', 'unavailable') 
GROUP BY category
ORDER BY category_revenue DESC
;

-- 'pc_gamer' and 'portateis_cozinha_e_preparadores_de_alimentos' don't have english translation
SELECT DISTINCT c.product_category_name, p.product_category_name_english
FROM products_clean as c
LEFT JOIN  category_translation as p ON p.product_category_name = c.product_category_name
WHERE p.product_category_name_english is null;

-- --------------------------------------------------------------------------------------------------------
-- 3.Delayed Deliveries and scores
-- --------------------------------------------------------------------------------------------------------
SELECT 
CASE
WHEN Delivery_Delay = 0 THEN 'On time'
WHEN Delivery_Delay < 0 THEN 'Early Delivery'
WHEN Delivery_Delay BETWEEN 1 AND 7 THEN '1 Week Delay'
WHEN Delivery_Delay BETWEEN 8 AND 30 THEN 'Less than a month Delay'
WHEN Delivery_Delay > 30 THEN 'More than a month Delay'
END AS delay_condition,
count(*) as number_of_orders , avg(average_review_score) as average_score
FROM(
SELECT o.order_id, datediff(o.order_delivered_customer_date, o.order_estimated_delivery_date) as Delivery_Delay , avg(r.review_score) as average_review_score 
FROM orders as o
JOIN order_reviews_clean as r ON o.order_id = r.order_id
WHERE o.order_purchase_timestamp >= '2017-01-01' AND o.order_purchase_timestamp < '2018-09-01' 
AND o.order_status = 'delivered' 
AND o.order_delivered_customer_date IS NOT NULL
GROUP BY r.order_id) as t
GROUP BY delay_condition
ORDER BY min(Delivery_Delay)
;

-- --------------------------------------------------------------------------------------------------------
-- 4.Delays in different states
-- --------------------------------------------------------------------------------------------------------
SELECT 
customer_state, 
count(*) as number_of_orders,
CASE
WHEN Delivery_Delay <= 0 THEN 'On time/Early Delivery'
WHEN Delivery_Delay > 0 THEN 'Delayed Delivery'
END AS delay_condition
FROM(
SELECT o.order_id, customer_state, datediff(o.order_delivered_customer_date, o.order_estimated_delivery_date) as Delivery_Delay 
FROM customers as c
JOIN orders as o ON c.customer_id = o.customer_id
WHERE o.order_purchase_timestamp >= '2017-01-01' AND o.order_purchase_timestamp < '2018-09-01' 
AND o.order_status = 'delivered' 
AND o.order_delivered_customer_date IS NOT NULL
) as t
GROUP BY delay_condition, customer_state
ORDER BY customer_state
;


SELECT 
customer_state, 
count(*) as number_of_orders,
sum(Delivery_Delay > 0) as number_of_delayed_orders,
sum(Delivery_Delay > 0) / count(*) * 100 as Delay_percentage
FROM(
SELECT o.order_id, customer_state, datediff(o.order_delivered_customer_date, o.order_estimated_delivery_date) as Delivery_Delay 
FROM customers as c
JOIN orders as o ON c.customer_id = o.customer_id
WHERE o.order_purchase_timestamp >= '2017-01-01' AND o.order_purchase_timestamp < '2018-09-01' 
AND o.order_status = 'delivered' 
AND o.order_delivered_customer_date IS NOT NULL
) as t
GROUP BY customer_state
ORDER BY Delay_percentage, number_of_delayed_orders
;


-- --------------------------------------------------------------------------------------------------------
-- 5.number and percentage of customers from different states
-- --------------------------------------------------------------------------------------------------------
SELECT customer_state, 
count(DISTINCT customer_unique_id) as number_of_customers_in_state,
round(count(DISTINCT customer_unique_id) / sum(count(DISTINCT customer_unique_id)) OVER() * 100, 2) as percentage_of_customers
FROM customers
GROUP BY customer_state
ORDER BY count(customer_unique_id) desc
;

-- About 40 customers are from more than one state
SELECT COUNT(DISTINCT customer_unique_id) FROM customers;

-- --------------------------------------------------------------------------------------------------------
-- 6.percentage of customers with more than one orders
-- --------------------------------------------------------------------------------------------------------
SELECT CASE
WHEN number_of_customer_orders > 1 THEN 'More than one order' 
WHEN number_of_customer_orders <=1 THEN 'One order' 
END as customer_type,
count(*) as number_of_customers,
round(count(*)/sum(count(*)) over()*100, 2) as pct
FROM(
SELECT count(DISTINCT order_id) as number_of_customer_orders
FROM customers as c
JOIN orders as o ON c.customer_id =  o.customer_id
WHERE o.order_status NOT IN ('canceled', 'unavailable')
GROUP BY c.customer_unique_id
) as t
GROUP BY customer_type
;




