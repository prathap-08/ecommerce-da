-- MySQL 8+ data loading script
-- Ensure local infile is enabled.
-- SET GLOBAL local_infile = 1;

LOAD DATA LOCAL INFILE 'C:/Users/prath/OneDrive/Desktop/e commers/data/orders.csv'
INTO TABLE orders
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, order_date, customer_id, customer_name, region);

LOAD DATA LOCAL INFILE 'C:/Users/prath/OneDrive/Desktop/e commers/data/products.csv'
INTO TABLE products
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(product_id, product_name, category, unit_price, unit_cost);

LOAD DATA LOCAL INFILE 'C:/Users/prath/OneDrive/Desktop/e commers/data/sales.csv'
INTO TABLE sales
FIELDS TERMINATED BY ',' ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(order_id, product_id, quantity, revenue);

SELECT 'orders' AS table_name, COUNT(*) AS row_count FROM orders
UNION ALL
SELECT 'products' AS table_name, COUNT(*) AS row_count FROM products
UNION ALL
SELECT 'sales' AS table_name, COUNT(*) AS row_count FROM sales;
