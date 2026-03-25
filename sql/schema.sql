-- E-commerce Sales Analysis Schema
-- PostgreSQL-compatible DDL

DROP TABLE IF EXISTS sales;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;

CREATE TABLE orders (
    order_id       VARCHAR(50) PRIMARY KEY,
    order_date     DATE NOT NULL,
    customer_id    VARCHAR(50) NOT NULL,
    customer_name  VARCHAR(150),
    region         VARCHAR(100) NOT NULL
);

CREATE TABLE products (
    product_id     VARCHAR(50) PRIMARY KEY,
    product_name   VARCHAR(200) NOT NULL,
    category       VARCHAR(100) NOT NULL,
    unit_price     NUMERIC(12, 2) NOT NULL,
    unit_cost      NUMERIC(12, 2)
);

CREATE TABLE sales (
    sale_id        BIGSERIAL PRIMARY KEY,
    order_id       VARCHAR(50) NOT NULL REFERENCES orders(order_id),
    product_id     VARCHAR(50) NOT NULL REFERENCES products(product_id),
    quantity       INT NOT NULL CHECK (quantity > 0),
    revenue        NUMERIC(14, 2) NOT NULL CHECK (revenue >= 0)
);

CREATE INDEX idx_orders_date ON orders(order_date);
CREATE INDEX idx_orders_region ON orders(region);
CREATE INDEX idx_sales_order ON sales(order_id);
CREATE INDEX idx_sales_product ON sales(product_id);
