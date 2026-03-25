-- Load cleaned processed CSVs into PostgreSQL advanced schema

COPY dim_customers(customer_id, customer_name, email, region, city, signup_date, segment, lifetime_value, order_frequency, avg_order_value, total_profit, first_order_date, last_order_date, customer_tenure_days)
FROM 'C:/Users/prath/OneDrive/Desktop/e commers/data/processed/dim_customers.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

COPY dim_products(product_id, product_name, category, brand, unit_price, unit_cost)
FROM 'C:/Users/prath/OneDrive/Desktop/e commers/data/processed/dim_products.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

COPY fact_orders(order_id, order_date, customer_id, region, order_status, order_revenue, order_profit, order_items_count)
FROM 'C:/Users/prath/OneDrive/Desktop/e commers/data/processed/fct_orders.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

COPY fact_order_items(order_id, line_no, product_id, quantity, unit_selling_price, discount_pct, total_revenue, unit_cost, line_cost, line_profit, category, brand, product_name)
FROM 'C:/Users/prath/OneDrive/Desktop/e commers/data/processed/fct_order_items.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');

COPY fact_payments(payment_id, order_id, payment_date, payment_method, payment_status, amount)
FROM 'C:/Users/prath/OneDrive/Desktop/e commers/data/processed/fct_payments.csv'
WITH (FORMAT csv, HEADER true, ENCODING 'UTF8');
