-- Load generated CSV data into PostgreSQL tables
-- Run this after sql/schema.sql

-- If your PostgreSQL server cannot access local paths, use \copy in psql with the same file names.

COPY orders(order_id, order_date, customer_id, customer_name, region)
FROM 'C:/Users/prath/OneDrive/Desktop/e commers/data/orders.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

COPY products(product_id, product_name, category, unit_price, unit_cost)
FROM 'C:/Users/prath/OneDrive/Desktop/e commers/data/products.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

COPY sales(order_id, product_id, quantity, revenue)
FROM 'C:/Users/prath/OneDrive/Desktop/e commers/data/sales.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

-- Quick row count checks
SELECT 'orders' AS table_name, COUNT(*) AS row_count FROM orders
UNION ALL
SELECT 'products' AS table_name, COUNT(*) AS row_count FROM products
UNION ALL
SELECT 'sales' AS table_name, COUNT(*) AS row_count FROM sales;
