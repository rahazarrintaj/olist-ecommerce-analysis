-- Data Quality CHECK

SELECT *
FROM olist.orders;

-- --------------------------------------------------------------------------------------------------------
-- checking distinct values of order_status
-- --------------------------------------------------------------------------------------------------------
SELECT DISTINCT order_status
FROM olist.orders;

SELECT order_status, count(*)
FROM olist.orders
GROUP BY order_status
;

SELECT *
FROM olist.orders
WHERE order_status = 'canceled';


-- --------------------------------------------------------------------------------------------------------
-- checking the matching of dates with the status
-- --------------------------------------------------------------------------------------------------------
SELECT order_status, count(*), sum(order_purchase_timestamp is null), sum(order_approved_at is null), 
sum(order_delivered_carrier_date is null), sum(order_delivered_customer_date is null), sum(order_estimated_delivery_date is null)
FROM olist.orders
GROUP BY order_status;
-- 8 delivered orders do not have a delivery date which will be neglected in future queries
-- 6 cancelled orders were delivered to the customer which were probably resent to the shop and will be neglected in future queries
-- other status had no issues

SELECT * 
FROM olist.orders
WHERE order_status = 'delivered' and order_delivered_customer_date is null;


-- --------------------------------------------------------------------------------------------------------
-- the first and last order dates (2016-09 to 2018-10)
-- --------------------------------------------------------------------------------------------------------
SELECT min(order_purchase_timestamp) as first_order, max(order_purchase_timestamp) as last_order
FROM olist.orders;

-- --------------------------------------------------------------------------------------------------------
-- the number of orders by months and year
-- --------------------------------------------------------------------------------------------------------
SELECT year(order_purchase_timestamp) as order_year, month(order_purchase_timestamp) as order_month, count(*)
FROM olist.orders
GROUP BY order_year, order_month
ORDER BY order_year, order_month asc
;
-- missing data in 2016-11
-- in the year 2016 the orders are significanlly lower which can be due to not entering the data
-- the above is also correct for 2018-09 and 2018-10
-- so we will keep the data but in analysis will start from 2017-01 to 2018-08


-- --------------------------------------------------------------------------------------------------------
-- checking if the order of dates are correct
-- --------------------------------------------------------------------------------------------------------
SELECT sum(date(order_purchase_timestamp) > date(order_approved_at)),
sum(date(order_approved_at) > date(order_delivered_carrier_date)), 
sum(date(order_purchase_timestamp) > date(order_delivered_carrier_date)), 
sum(date(order_delivered_carrier_date) > date(order_delivered_customer_date)), 
sum(date(order_purchase_timestamp) > date(order_delivered_customer_date)),
sum(date(order_purchase_timestamp) > date(order_estimated_delivery_date))
FROM olist.orders
;
-- 1359 orders delivery to carrier time is lower than order being approved
-- 23 orders delivery to customer time is lower than order being delivered to carrier
-- 2 orders delivery to carrier time is lower than order being purchased
-- None of the above dates are used in the analysis and they are probabily typing issues

SELECT order_approved_at, order_delivered_carrier_date
FROM olist.orders
WHERE order_approved_at > order_delivered_carrier_date
;



SELECT sum(timestampdiff(year, order_delivered_carrier_date, order_approved_at) >= 1)  as YearDiff,
sum(timestampdiff(month, order_delivered_carrier_date, order_approved_at) >= 1)  as MonthDiff,
sum(timestampdiff(day, order_delivered_carrier_date, order_approved_at) >= 1)  as DayDiff,
sum(timestampdiff(hour, order_delivered_carrier_date, order_approved_at) >= 1)  as HourDiff,
sum(timestampdiff(minute, order_delivered_carrier_date, order_approved_at) >= 1)  as MinuteDiff,
sum(timestampdiff(second, order_delivered_carrier_date, order_approved_at) >= 1)  as SecondDiff
FROM olist.orders
;
-- the off dates are mostly less than a day and only one month mistake


SELECT sum(timestampdiff(year, order_delivered_customer_date, order_delivered_carrier_date) >= 1)  as YearDiff,
sum(timestampdiff(month, order_delivered_customer_date, order_delivered_carrier_date) >= 1)  as MonthDiff,
sum(timestampdiff(day, order_delivered_customer_date, order_delivered_carrier_date) >= 1)  as DayDiff,
sum(timestampdiff(hour, order_delivered_customer_date, order_delivered_carrier_date) >= 1)  as HourDiff,
sum(timestampdiff(minute, order_delivered_customer_date, order_delivered_carrier_date) >= 1)  as MinuteDiff,
sum(timestampdiff(second, order_delivered_customer_date, order_delivered_carrier_date) >= 1)  as SecondDiff
FROM olist.orders
;
-- the off dates are mostly apart by day

SELECT *
FROM olist.orders
WHERE timestampdiff(month, order_delivered_carrier_date, order_approved_at) >= 1
;
-- Other dates are completely correct which suggests the idea of it being a typo


-- --------------------------------------------------------------------------------------------------------
-- checking the number of customers without orders 
-- --------------------------------------------------------------------------------------------------------
SELECT orders.customer_id, customers.customer_id, orders.order_id
FROM orders
RIGHT JOIN customers ON orders.customer_id = customers.customer_id
WHERE orders.order_id IS NULL
;

-- --------------------------------------------------------------------------------------------------------
-- checking the number of orders without customers  (0)
-- --------------------------------------------------------------------------------------------------------
SELECT count(*)
FROM orders
LEFT JOIN customers ON orders.customer_id = customers.customer_id
WHERE customers.customer_id IS NULL
;

-- --------------------------------------------------------------------------------------------------------
-- checking the number of orders without items  (775)
-- --------------------------------------------------------------------------------------------------------
SELECT count(*)
FROM orders
LEFT JOIN order_items ON orders.order_id = order_items.order_id
WHERE order_items.order_item_id IS NULL
;

SELECT orders.order_status, COUNT(*)
FROM orders
LEFT JOIN order_items ON orders.order_id = order_items.order_id
WHERE order_items.order_id IS NULL
GROUP BY orders.order_status;
-- 164 cancelled, 603 unavailable, 2 invoiced, 5 created, 1 shipped(won't be used in analysis)

-- --------------------------------------------------------------------------------------------------------
-- checking the number of items without products  (0)
-- --------------------------------------------------------------------------------------------------------
SELECT COUNT(*)
FROM order_items
LEFT JOIN products_clean ON order_items.product_id = products_clean.product_id
WHERE products_clean.product_id IS NULL
;

-- --------------------------------------------------------------------------------------------------------
-- checking the number of orders without reviews  (768)
-- --------------------------------------------------------------------------------------------------------
SELECT count(*)
FROM orders
LEFT JOIN order_reviews_clean ON orders.order_id = order_reviews_clean.order_id
WHERE order_reviews_clean.review_id IS NULL
;

-- orders with more than one review
SELECT count(DISTINCT order_id), count(order_id)
FROM order_reviews_clean
;

-- max number of items in one order
SELECT max(order_item_id)
FROM order_items
;