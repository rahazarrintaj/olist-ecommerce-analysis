-- DATA EXPLORATION

-- customer_unique_id is unique for each customer
-- customer_id is for each order
SELECT * from olist.customers limit 10;
DESCRIBE olist.customers;
SELECT count(*), count(DISTINCT customer_id), count(DISTINCT customer_unique_id) from olist.customers;

SELECT * from olist.orders limit 10;
DESCRIBE olist.orders;

SELECT * from olist.products_clean limit 10;
DESCRIBE olist.products;

SELECT * from olist.order_items limit 10;
DESCRIBE olist.order_items;

SELECT * from olist.order_reviews_clean limit 10;
DESCRIBE olist.order_reviews;

SELECT * from olist.category_translation limit 10;
DESCRIBE olist.category_translation;



