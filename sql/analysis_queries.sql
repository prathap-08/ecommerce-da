-- E-commerce Sales Analysis Queries
-- PostgreSQL syntax

-- Base joined dataset for reuse
WITH base AS (
    SELECT
        o.order_id,
        o.order_date,
        DATE_TRUNC('month', o.order_date) AS month_start,
        o.customer_id,
        o.customer_name,
        o.region,
        p.product_id,
        p.product_name,
        p.category,
        p.unit_price,
        p.unit_cost,
        s.quantity,
        s.revenue,
        (s.revenue - COALESCE(p.unit_cost, 0) * s.quantity) AS profit
    FROM sales s
    JOIN orders o ON o.order_id = s.order_id
    JOIN products p ON p.product_id = s.product_id
)
SELECT * FROM base LIMIT 5;


-- 1) Monthly sales trends + seasonality
WITH monthly AS (
    SELECT
        DATE_TRUNC('month', o.order_date) AS month_start,
        EXTRACT(MONTH FROM o.order_date) AS month_num,
        SUM(s.revenue) AS revenue,
        SUM(s.quantity) AS units_sold,
        COUNT(DISTINCT o.order_id) AS orders
    FROM sales s
    JOIN orders o ON o.order_id = s.order_id
    GROUP BY 1, 2
)
SELECT
    month_start,
    month_num,
    revenue,
    units_sold,
    orders,
    ROUND(revenue / NULLIF(orders, 0), 2) AS aov,
    LAG(revenue) OVER (ORDER BY month_start) AS prev_month_revenue,
    ROUND(
        100.0 * (revenue - LAG(revenue) OVER (ORDER BY month_start))
        / NULLIF(LAG(revenue) OVER (ORDER BY month_start), 0),
        2
    ) AS mom_growth_pct
FROM monthly
ORDER BY month_start;

-- Optional seasonality profile (average revenue by calendar month across years)
WITH monthly AS (
    SELECT
        EXTRACT(MONTH FROM o.order_date) AS month_num,
        SUM(s.revenue) AS revenue
    FROM sales s
    JOIN orders o ON o.order_id = s.order_id
    GROUP BY 1, DATE_TRUNC('month', o.order_date)
)
SELECT
    month_num,
    ROUND(AVG(revenue), 2) AS avg_revenue,
    ROUND(100.0 * AVG(revenue) / SUM(AVG(revenue)) OVER (), 2) AS seasonal_share_pct
FROM monthly
GROUP BY month_num
ORDER BY month_num;


-- 2) Top 10 best-selling products by revenue
SELECT
    p.product_id,
    p.product_name,
    p.category,
    SUM(s.quantity) AS total_units,
    SUM(s.revenue) AS total_revenue,
    ROUND(100.0 * SUM(s.revenue) / SUM(SUM(s.revenue)) OVER (), 2) AS revenue_share_pct
FROM sales s
JOIN products p ON p.product_id = s.product_id
GROUP BY p.product_id, p.product_name, p.category
ORDER BY total_revenue DESC
LIMIT 10;


-- 3) Region with highest profit margin
-- Requires products.unit_cost populated.
SELECT
    o.region,
    SUM(s.revenue) AS total_revenue,
    SUM(s.revenue - COALESCE(p.unit_cost, 0) * s.quantity) AS total_profit,
    ROUND(
        100.0 * SUM(s.revenue - COALESCE(p.unit_cost, 0) * s.quantity)
        / NULLIF(SUM(s.revenue), 0),
        2
    ) AS profit_margin_pct
FROM sales s
JOIN orders o ON o.order_id = s.order_id
JOIN products p ON p.product_id = s.product_id
GROUP BY o.region
ORDER BY profit_margin_pct DESC;


-- 4) Customers with highest lifetime value (LTV)
SELECT
    o.customer_id,
    COALESCE(MAX(o.customer_name), o.customer_id) AS customer_name,
    COUNT(DISTINCT o.order_id) AS orders_count,
    SUM(s.quantity) AS lifetime_units,
    SUM(s.revenue) AS lifetime_revenue,
    ROUND(SUM(s.revenue) / NULLIF(COUNT(DISTINCT o.order_id), 0), 2) AS avg_order_value
FROM sales s
JOIN orders o ON o.order_id = s.order_id
GROUP BY o.customer_id
ORDER BY lifetime_revenue DESC
LIMIT 20;


-- 5) Detect drop in sales and likely reasons
-- Step A: Find months where revenue dropped more than 10% MoM
WITH monthly AS (
    SELECT
        DATE_TRUNC('month', o.order_date) AS month_start,
        SUM(s.revenue) AS revenue,
        SUM(s.quantity) AS units,
        COUNT(DISTINCT o.order_id) AS orders
    FROM sales s
    JOIN orders o ON o.order_id = s.order_id
    GROUP BY 1
), flagged AS (
    SELECT
        month_start,
        revenue,
        units,
        orders,
        LAG(revenue) OVER (ORDER BY month_start) AS prev_revenue,
        ROUND(
            100.0 * (revenue - LAG(revenue) OVER (ORDER BY month_start))
            / NULLIF(LAG(revenue) OVER (ORDER BY month_start), 0),
            2
        ) AS mom_growth_pct
    FROM monthly
)
SELECT *
FROM flagged
WHERE mom_growth_pct <= -10
ORDER BY month_start;

-- Step B: Contribution by region in drop months
WITH monthly_region AS (
    SELECT
        DATE_TRUNC('month', o.order_date) AS month_start,
        o.region,
        SUM(s.revenue) AS revenue
    FROM sales s
    JOIN orders o ON o.order_id = s.order_id
    GROUP BY 1, 2
), delta AS (
    SELECT
        month_start,
        region,
        revenue,
        LAG(revenue) OVER (PARTITION BY region ORDER BY month_start) AS prev_revenue
    FROM monthly_region
)
SELECT
    month_start,
    region,
    revenue,
    prev_revenue,
    ROUND(100.0 * (revenue - prev_revenue) / NULLIF(prev_revenue, 0), 2) AS region_mom_growth_pct
FROM delta
WHERE prev_revenue IS NOT NULL
ORDER BY month_start, region_mom_growth_pct ASC;

-- Step C: Contribution by category in drop months
WITH monthly_category AS (
    SELECT
        DATE_TRUNC('month', o.order_date) AS month_start,
        p.category,
        SUM(s.revenue) AS revenue
    FROM sales s
    JOIN orders o ON o.order_id = s.order_id
    JOIN products p ON p.product_id = s.product_id
    GROUP BY 1, 2
), delta AS (
    SELECT
        month_start,
        category,
        revenue,
        LAG(revenue) OVER (PARTITION BY category ORDER BY month_start) AS prev_revenue
    FROM monthly_category
)
SELECT
    month_start,
    category,
    revenue,
    prev_revenue,
    ROUND(100.0 * (revenue - prev_revenue) / NULLIF(prev_revenue, 0), 2) AS category_mom_growth_pct
FROM delta
WHERE prev_revenue IS NOT NULL
ORDER BY month_start, category_mom_growth_pct ASC;
