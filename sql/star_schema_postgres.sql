-- PostgreSQL star-schema helper objects for Power BI

-- Date dimension table from generated CSV
DROP TABLE IF EXISTS dim_date;
CREATE TABLE dim_date (
    date_key      INT PRIMARY KEY,
    date          DATE NOT NULL,
    year          INT NOT NULL,
    quarter       VARCHAR(2) NOT NULL,
    month_num     INT NOT NULL,
    month_name    VARCHAR(20) NOT NULL,
    week_of_year  INT NOT NULL,
    day_of_month  INT NOT NULL,
    day_name      VARCHAR(20) NOT NULL,
    is_weekend    INT NOT NULL
);

-- Load date dimension from CSV
COPY dim_date(date_key, date, year, quarter, month_num, month_name, week_of_year, day_of_month, day_name, is_weekend)
FROM 'C:/Users/prath/OneDrive/Desktop/e commers/data/date_dimension.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

-- Optional enriched fact view for BI tools
DROP VIEW IF EXISTS fact_sales_enriched;
CREATE VIEW fact_sales_enriched AS
SELECT
    o.order_id,
    o.order_date,
    CAST(TO_CHAR(o.order_date, 'YYYYMMDD') AS INT) AS order_date_key,
    o.customer_id,
    o.customer_name,
    o.region,
    s.product_id,
    p.product_name,
    p.category,
    s.quantity,
    s.revenue,
    p.unit_price,
    p.unit_cost,
    (s.revenue - COALESCE(p.unit_cost, 0) * s.quantity) AS profit
FROM sales s
JOIN orders o ON o.order_id = s.order_id
JOIN products p ON p.product_id = s.product_id;
