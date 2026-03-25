-- Optimized SQL analytics layer

-- 1) Top selling products by revenue and units
SELECT
    oi.product_id,
    oi.product_name,
    oi.category,
    SUM(oi.quantity) AS units_sold,
    SUM(oi.total_revenue) AS total_revenue,
    SUM(oi.line_profit) AS total_profit
FROM fact_order_items oi
JOIN fact_orders o ON o.order_id = oi.order_id
WHERE o.order_status = 'Delivered'
GROUP BY oi.product_id, oi.product_name, oi.category
ORDER BY total_revenue DESC
LIMIT 20;

-- 2) Monthly revenue trends with MoM growth
WITH monthly AS (
    SELECT
        DATE_TRUNC('month', o.order_date) AS month_start,
        SUM(o.order_revenue) AS revenue,
        SUM(o.order_profit) AS profit,
        COUNT(DISTINCT o.order_id) AS orders
    FROM fact_orders o
    WHERE o.order_status = 'Delivered'
    GROUP BY 1
)
SELECT
    month_start,
    revenue,
    profit,
    orders,
    ROUND(revenue / NULLIF(orders, 0), 2) AS avg_order_value,
    LAG(revenue) OVER (ORDER BY month_start) AS prev_month_revenue,
    ROUND(
        100.0 * (revenue - LAG(revenue) OVER (ORDER BY month_start))
        / NULLIF(LAG(revenue) OVER (ORDER BY month_start), 0),
        2
    ) AS mom_growth_pct
FROM monthly
ORDER BY month_start;

-- 3) Customer segmentation using RFM
WITH base AS (
    SELECT
        o.customer_id,
        MAX(o.order_date) AS last_order_date,
        COUNT(DISTINCT o.order_id) AS frequency,
        SUM(o.order_revenue) AS monetary,
        DATE_PART('day', DATE '2026-01-01' - MAX(o.order_date))::INT AS recency_days
    FROM fact_orders o
    WHERE o.order_status = 'Delivered'
    GROUP BY o.customer_id
), scored AS (
    SELECT
        customer_id,
        recency_days,
        frequency,
        monetary,
        6 - NTILE(5) OVER (ORDER BY recency_days) AS r_score,
        NTILE(5) OVER (ORDER BY frequency) AS f_score,
        NTILE(5) OVER (ORDER BY monetary) AS m_score
    FROM base
)
SELECT
    customer_id,
    recency_days,
    frequency,
    monetary,
    r_score,
    f_score,
    m_score,
    CONCAT(r_score, f_score, m_score) AS rfm_code,
    CASE
        WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
        WHEN r_score >= 4 AND f_score >= 3 THEN 'Loyal Customers'
        WHEN r_score >= 3 AND f_score >= 2 AND m_score >= 2 THEN 'Potential Loyalists'
        WHEN r_score <= 2 AND f_score >= 4 THEN 'At Risk'
        WHEN r_score = 1 AND f_score <= 2 THEN 'Lost'
        ELSE 'Need Attention'
    END AS segment
FROM scored
ORDER BY monetary DESC;
