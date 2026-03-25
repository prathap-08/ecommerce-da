-- MySQL 8+ analysis queries

-- 1) Monthly sales trends and seasonality
WITH monthly AS (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m-01') AS month_start,
        MONTH(o.order_date) AS month_num,
        SUM(s.revenue) AS revenue,
        SUM(s.quantity) AS units_sold,
        COUNT(DISTINCT o.order_id) AS orders
    FROM sales s
    JOIN orders o ON o.order_id = s.order_id
    GROUP BY DATE_FORMAT(o.order_date, '%Y-%m-01'), MONTH(o.order_date)
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

WITH monthly AS (
    SELECT
        MONTH(o.order_date) AS month_num,
        DATE_FORMAT(o.order_date, '%Y-%m-01') AS ym,
        SUM(s.revenue) AS revenue
    FROM sales s
    JOIN orders o ON o.order_id = s.order_id
    GROUP BY MONTH(o.order_date), DATE_FORMAT(o.order_date, '%Y-%m-01')
)
SELECT
    month_num,
    ROUND(AVG(revenue), 2) AS avg_revenue,
    ROUND(100.0 * AVG(revenue) / SUM(AVG(revenue)) OVER (), 2) AS seasonal_share_pct
FROM monthly
GROUP BY month_num
ORDER BY month_num;

-- 2) Top 10 products by revenue
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

-- 4) Customers with highest LTV
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

-- 5) Detect drop in sales and possible reasons
WITH monthly AS (
    SELECT
        DATE_FORMAT(o.order_date, '%Y-%m-01') AS month_start,
        SUM(s.revenue) AS revenue,
        SUM(s.quantity) AS units,
        COUNT(DISTINCT o.order_id) AS orders
    FROM sales s
    JOIN orders o ON o.order_id = s.order_id
    GROUP BY DATE_FORMAT(o.order_date, '%Y-%m-01')
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
