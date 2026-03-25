-- Advanced PostgreSQL schema for end-to-end e-commerce analytics

DROP TABLE IF EXISTS fact_order_items;
DROP TABLE IF EXISTS fact_payments;
DROP TABLE IF EXISTS fact_orders;
DROP TABLE IF EXISTS dim_customers;
DROP TABLE IF EXISTS dim_products;

CREATE TABLE dim_customers (
    customer_id       VARCHAR(20) PRIMARY KEY,
    customer_name     VARCHAR(150),
    email             VARCHAR(200),
    region            VARCHAR(50),
    city              VARCHAR(100),
    signup_date       DATE,
    segment           VARCHAR(50),
    lifetime_value    NUMERIC(14, 2),
    order_frequency   INT,
    avg_order_value   NUMERIC(14, 2),
    total_profit      NUMERIC(14, 2),
    first_order_date  DATE,
    last_order_date   DATE,
    customer_tenure_days INT
);

CREATE TABLE dim_products (
    product_id        VARCHAR(20) PRIMARY KEY,
    product_name      VARCHAR(200),
    category          VARCHAR(100),
    brand             VARCHAR(100),
    unit_price        NUMERIC(12, 2),
    unit_cost         NUMERIC(12, 2)
);

CREATE TABLE fact_orders (
    order_id          VARCHAR(20) PRIMARY KEY,
    order_date        DATE NOT NULL,
    customer_id       VARCHAR(20) NOT NULL REFERENCES dim_customers(customer_id),
    region            VARCHAR(50),
    order_status      VARCHAR(30),
    order_revenue     NUMERIC(14, 2),
    order_profit      NUMERIC(14, 2),
    order_items_count INT
);

CREATE TABLE fact_order_items (
    order_id             VARCHAR(20) NOT NULL REFERENCES fact_orders(order_id),
    line_no              INT NOT NULL,
    product_id           VARCHAR(20) NOT NULL REFERENCES dim_products(product_id),
    quantity             INT NOT NULL,
    unit_selling_price   NUMERIC(12, 2),
    discount_pct         NUMERIC(6, 2),
    total_revenue        NUMERIC(14, 2),
    unit_cost            NUMERIC(12, 2),
    line_cost            NUMERIC(14, 2),
    line_profit          NUMERIC(14, 2),
    category             VARCHAR(100),
    brand                VARCHAR(100),
    product_name         VARCHAR(200),
    PRIMARY KEY (order_id, line_no, product_id)
);

CREATE TABLE fact_payments (
    payment_id        VARCHAR(30) PRIMARY KEY,
    order_id          VARCHAR(20) NOT NULL REFERENCES fact_orders(order_id),
    payment_date      DATE,
    payment_method    VARCHAR(50),
    payment_status    VARCHAR(30),
    amount            NUMERIC(14, 2)
);

CREATE INDEX idx_fact_orders_date ON fact_orders(order_date);
CREATE INDEX idx_fact_orders_customer ON fact_orders(customer_id);
CREATE INDEX idx_fact_orders_region ON fact_orders(region);
CREATE INDEX idx_fact_items_product ON fact_order_items(product_id);
CREATE INDEX idx_fact_items_category ON fact_order_items(category);
CREATE INDEX idx_fact_payments_order ON fact_payments(order_id);
