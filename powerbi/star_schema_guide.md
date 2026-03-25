# Power BI Star Schema Guide

## Objective
Use a clean model for performance and easier DAX:
- Dimensions: `orders` attributes (or split customer/region), `products`, `dim_date`
- Fact: `sales` (or `fact_sales_enriched` view from SQL)

## Date Dimension Setup
1. Generate date table CSV:
   - PowerShell: `./scripts/generate_date_dimension.ps1`
2. Load `data/date_dimension.csv` into Power BI.
3. Create relationship:
   - `date_dimension[date]` (or date_key) -> `orders[order_date]`

## Recommended Model (Practical)
- Keep source tables: `orders`, `products`, `sales`, `date_dimension`
- Relationships:
  - `orders[order_id]` 1:* `sales[order_id]`
  - `products[product_id]` 1:* `sales[product_id]`
  - `date_dimension[date]` 1:* `orders[order_date]`

## Why This Helps
- Fast filtering by Year/Quarter/Month/Week.
- Correct time-intelligence DAX (MoM, YoY).
- Cleaner visuals and less duplicated logic.

## Optional SQL Helper
If using PostgreSQL, run `sql/star_schema_postgres.sql` to create:
- `dim_date` table
- `fact_sales_enriched` view
