-- SQL Server schema for E-commerce Sales Analysis

IF OBJECT_ID('sales', 'U') IS NOT NULL DROP TABLE sales;
IF OBJECT_ID('orders', 'U') IS NOT NULL DROP TABLE orders;
IF OBJECT_ID('products', 'U') IS NOT NULL DROP TABLE products;

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
    unit_price     DECIMAL(12, 2) NOT NULL,
    unit_cost      DECIMAL(12, 2)
);

CREATE TABLE sales (
    sale_id        BIGINT IDENTITY(1,1) PRIMARY KEY,
    order_id       VARCHAR(50) NOT NULL,
    product_id     VARCHAR(50) NOT NULL,
    quantity       INT NOT NULL CHECK (quantity > 0),
    revenue        DECIMAL(14, 2) NOT NULL CHECK (revenue >= 0),
    CONSTRAINT fk_sales_order FOREIGN KEY (order_id) REFERENCES orders(order_id),
    CONSTRAINT fk_sales_product FOREIGN KEY (product_id) REFERENCES products(product_id)
);

CREATE INDEX idx_orders_date ON orders(order_date);
CREATE INDEX idx_orders_region ON orders(region);
CREATE INDEX idx_sales_order ON sales(order_id);
CREATE INDEX idx_sales_product ON sales(product_id);
