-- SQL Server data loading script
-- Requires SQL Server service account access to file path.

BULK INSERT orders
FROM 'C:\Users\prath\OneDrive\Desktop\e commers\data\orders.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    CODEPAGE = '65001'
);

BULK INSERT products
FROM 'C:\Users\prath\OneDrive\Desktop\e commers\data\products.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    CODEPAGE = '65001'
);

BULK INSERT sales
FROM 'C:\Users\prath\OneDrive\Desktop\e commers\data\sales.csv'
WITH (
    FORMAT = 'CSV',
    FIRSTROW = 2,
    CODEPAGE = '65001'
);

SELECT 'orders' AS table_name, COUNT(*) AS row_count FROM orders
UNION ALL
SELECT 'products' AS table_name, COUNT(*) AS row_count FROM products
UNION ALL
SELECT 'sales' AS table_name, COUNT(*) AS row_count FROM sales;
