-- =====================================================================
-- DATA CLEANING
-- Goal : build *_clean tables from *_raw and fix data-quality problems
-- Rule : raw data stays untouched (except one documented repair);
--        all analysis reads from *_clean for order_reviews and products
-- NOTE : lines marked [ONE-TIME] were already executed. They are commented
--        out because running them again causes errors or duplicate rows.
-- =====================================================================
USE olist;

-- =====================================================================
-- 1. SETUP: raw / clean copies (order_reviews, products)
-- =====================================================================

-- [ONE-TIME] rename originals to *_raw (fails if run twice)
-- ALTER TABLE olist.order_reviews RENAME TO olist.order_reviews_raw;
-- ALTER TABLE olist.products      RENAME TO olist.products_raw;

-- [ONE-TIME] create empty clean tables (fails: table already exists)
-- CREATE TABLE olist.order_reviews_clean LIKE olist.order_reviews_raw;
-- CREATE TABLE olist.products_clean      LIKE olist.products_raw;

-- =====================================================================
-- 2. STRUCTURAL REPAIR: one row corrupted during LOAD DATA (order_reviews)
-- Cause  : a quote inside the comment text broke the row, so the dates
--          ended up inside the message and the next row was swallowed.
-- Impact : 1 row corrupted + 1 row missing (review_id 29a50943...)
-- Values were taken from the original CSV.
-- =====================================================================

-- Inspect the corrupted row (zero dates)
SELECT *
FROM olist.order_reviews_raw
WHERE review_creation_date LIKE '0000%' OR review_answer_timestamp LIKE '0000%';

-- Repair in raw (safe to re-run: same result every time)
UPDATE olist.order_reviews_raw
SET review_creation_date = '2017-03-04 00:00:00'
WHERE review_creation_date LIKE '0000%';

UPDATE olist.order_reviews_raw
SET review_answer_timestamp = '2017-03-09 22:01:37'
WHERE review_answer_timestamp LIKE '0000%';

UPDATE olist.order_reviews_raw
SET review_comment_message = 'foi escrito que o produto já foi entregue, mas não chegou nada'
WHERE review_id = '636b237e87574ba29654deaba9eb9797';

-- Check the repaired row
SELECT *
FROM olist.order_reviews_raw
WHERE order_id = 'd7361a834a2dd8db2f6f133ce291ab6b';

-- =====================================================================
-- 3. POPULATE CLEAN TABLES FROM RAW
-- =====================================================================

-- [ONE-TIME] copy rows (running again duplicates every row)
-- INSERT INTO olist.order_reviews_clean
-- SELECT * FROM olist.order_reviews_raw;

-- [ONE-TIME] add the row that was swallowed during import (duplicates it if re-run)
-- INSERT INTO olist.order_reviews_clean
--   (review_id, order_id, review_score, review_comment_title,
--    review_comment_message, review_creation_date, review_answer_timestamp)
-- VALUES
--   ('29a50943bdeaba02e4a222241a4b583a', 'f63f9a7699e3674c80a4ba92e56dfbb8', 5, '',
--    'Minha primeira compra to satisfeito muito bom',
--    '2017-10-11 00:00:00', '2017-10-11 15:56:12');

-- [ONE-TIME] copy rows (running again duplicates every row)
-- INSERT INTO olist.products_clean
-- SELECT * FROM olist.products_raw;

-- Check: the swallowed row now exists
SELECT *
FROM olist.order_reviews_clean
WHERE review_id = '29a50943bdeaba02e4a222241a4b583a';

-- =====================================================================
-- 4. BLANK -> NULL (text columns only; safe to re-run)
-- Method: count before, update each column separately, count after
-- =====================================================================

-- 4.1 order_reviews_clean
-- Before: title (NULL + '') = 87656 | message (NULL + '') = 58247
SELECT COUNT(*)
FROM olist.order_reviews_clean
WHERE review_comment_title = '' OR review_comment_title IS NULL;

SELECT COUNT(*)
FROM olist.order_reviews_clean
WHERE review_comment_message = '' OR review_comment_message IS NULL;

UPDATE olist.order_reviews_clean
SET review_comment_title = NULL
WHERE review_comment_title = '';

UPDATE olist.order_reviews_clean
SET review_comment_message = NULL
WHERE review_comment_message = '';

-- After: NULL count must equal the "before" totals
SELECT COUNT(*)
FROM olist.order_reviews_clean
WHERE review_comment_title IS NULL;      -- 87656

SELECT COUNT(*)
FROM olist.order_reviews_clean
WHERE review_comment_message IS NULL;    -- 58247

-- 4.2 products_clean
-- Before: 610
SELECT COUNT(*)
FROM olist.products_clean
WHERE product_category_name = '' OR product_category_name IS NULL;

UPDATE olist.products_clean
SET product_category_name = NULL
WHERE product_category_name = '';

-- After: 610
SELECT COUNT(*)
FROM olist.products_clean
WHERE product_category_name IS NULL;

-- =====================================================================
-- 5. TABLES CHECKED, NO CHANGE NEEDED (checks kept as documentation)
-- =====================================================================

-- category_translation: blank/NULL English names
SELECT *
FROM olist.category_translation
WHERE product_category_name_english = '' OR product_category_name_english IS NULL;
-- result: ___ rows   (fill in)

-- customers: blank/NULL state
SELECT *
FROM olist.customers
WHERE customer_state = '' OR customer_state IS NULL;
-- result: 0 rows (the NULL row in the grid is Workbench's empty "new row")

-- order_items: freight_value
-- WARNING: "= ''" on a numeric column matches 0, so this query returns zeros
SELECT *
FROM olist.order_items
WHERE freight_value = '' OR freight_value IS NULL;
-- result: 383 rows, all 0.00 -> valid zeros (free shipping), kept as-is (confirm with CSV)

-- orders: estimated delivery date
SELECT *
FROM olist.orders
WHERE order_estimated_delivery_date LIKE '' OR order_estimated_delivery_date IS NULL;
-- result: ___ rows   (fill in)


-- =====================================================================
-- Find Duplicates
-- =====================================================================
-- only checking the tables WITHOUT primary keys
SELECT order_id, order_item_id, COUNT(*) AS cnt
FROM olist.order_items
GROUP BY order_id, order_item_id
HAVING COUNT(*) > 1;


SELECT order_id, review_id, count(*)
FROM olist.order_reviews_clean
GROUP BY order_id, review_id
HAVING count(*) > 1;

SELECT product_category_name, product_category_name_english, count(*)
FROM olist.category_translation
GROUP BY product_category_name, product_category_name_english
HAVING count(*) > 1;

-- No duplicate data rows in any table
