USE olist;

CREATE TABLE customers (
  customer_id VARCHAR(50) PRIMARY KEY,
  customer_unique_id VARCHAR(50),
  customer_zip_code_prefix VARCHAR(10),
  customer_city VARCHAR(100),
  customer_state CHAR(2)
);

CREATE TABLE orders (
  order_id VARCHAR(50) PRIMARY KEY,
  customer_id VARCHAR(50),
  order_status VARCHAR(20),
  order_purchase_timestamp DATETIME,
  order_approved_at DATETIME,
  order_delivered_carrier_date DATETIME,
  order_delivered_customer_date DATETIME,
  order_estimated_delivery_date DATETIME
);

CREATE TABLE order_items (
  order_id VARCHAR(50),
  order_item_id INT,
  product_id VARCHAR(50),
  seller_id VARCHAR(50),
  shipping_limit_date DATETIME,
  price DECIMAL(10,2),
  freight_value DECIMAL(10,2)
);

CREATE TABLE products (
  product_id VARCHAR(50) PRIMARY KEY,
  product_category_name VARCHAR(100),
  product_name_lenght INT,
  product_description_lenght INT,
  product_photos_qty INT,
  product_weight_g INT,
  product_length_cm INT,
  product_height_cm INT,
  product_width_cm INT
);

CREATE TABLE order_reviews (
  review_id VARCHAR(50),
  order_id VARCHAR(50),
  review_score INT,
  review_comment_title TEXT,
  review_comment_message TEXT,
  review_creation_date DATETIME,
  review_answer_timestamp DATETIME
);

CREATE TABLE category_translation (
  product_category_name VARCHAR(100),
  product_category_name_english VARCHAR(100)
);

SET GLOBAL local_infile = 1;
SHOW VARIABLES LIKE 'local_infile';

USE olist;

-- 1) customers
LOAD DATA LOCAL INFILE 'D:/DATA ANALYSIS/Projects/Brazilian E-commerce Public Dtaset by Olist/Brazilian E-commerce Public Dtaset by Olist/olist_customers_dataset.csv'
INTO TABLE customers
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- 2) orders (تاریخ‌های خالی را NULL می‌کند)
LOAD DATA LOCAL INFILE 'D:/DATA ANALYSIS/Projects/Brazilian E-commerce Public Dtaset by Olist/Brazilian E-commerce Public Dtaset by Olist/olist_orders_dataset.csv'
INTO TABLE orders
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(order_id, customer_id, order_status, order_purchase_timestamp, @approved, @carrier, @customer_date, order_estimated_delivery_date)
SET order_approved_at = NULLIF(@approved, ''),
    order_delivered_carrier_date = NULLIF(@carrier, ''),
    order_delivered_customer_date = NULLIF(@customer_date, '');

-- 3) order_items
LOAD DATA LOCAL INFILE 'D:/DATA ANALYSIS/Projects/Brazilian E-commerce Public Dtaset by Olist/Brazilian E-commerce Public Dtaset by Olist/olist_order_items_dataset.csv'
INTO TABLE order_items
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- 4) products (عددهای خالی را NULL می‌کند)
LOAD DATA LOCAL INFILE 'D:/DATA ANALYSIS/Projects/Brazilian E-commerce Public Dtaset by Olist/Brazilian E-commerce Public Dtaset by Olist/olist_products_dataset.csv'
INTO TABLE products
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(product_id, product_category_name, @name_len, @desc_len, @photos, @weight, @length, @height, @width)
SET product_name_lenght = NULLIF(@name_len, ''),
    product_description_lenght = NULLIF(@desc_len, ''),
    product_photos_qty = NULLIF(@photos, ''),
    product_weight_g = NULLIF(@weight, ''),
    product_length_cm = NULLIF(@length, ''),
    product_height_cm = NULLIF(@height, ''),
    product_width_cm = NULLIF(@width, '');

-- 5) order_reviews
LOAD DATA LOCAL INFILE 'D:/DATA ANALYSIS/Projects/Brazilian E-commerce Public Dtaset by Olist/Brazilian E-commerce Public Dtaset by Olist/olist_order_reviews_dataset.csv'
INTO TABLE order_reviews
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;

-- 6) category_translation
LOAD DATA LOCAL INFILE 'D:/DATA ANALYSIS/Projects/Brazilian E-commerce Public Dtaset by Olist/Brazilian E-commerce Public Dtaset by Olist/product_category_name_translation.csv'
INTO TABLE category_translation
FIELDS TERMINATED BY ',' OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES;