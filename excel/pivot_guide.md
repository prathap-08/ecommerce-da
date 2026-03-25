# Excel Pivot Table Guide

Use this quick flow after cleaning your joined dataset (Orders + Sales + Products).

## Recommended Combined Columns
- order_id
- order_date
- year
- month_name
- customer_id
- customer_name
- region
- product_id
- product_name
- category
- quantity
- revenue
- profit (if unit_cost available)

## Pivot 1: Monthly Trend
- Rows: `year`, `month_name`
- Values: Sum of `revenue`, Sum of `quantity`, Distinct Count of `order_id`
- Add calculated field: `AOV = revenue / order_count`
- Visual: Line chart for revenue

## Pivot 2: Top Products
- Rows: `product_name`
- Values: Sum of `revenue`, Sum of `quantity`
- Filters: `year`, `region`
- Sort descending by revenue, keep top 10

## Pivot 3: Regional Profitability
- Rows: `region`
- Values: Sum of `revenue`, Sum of `profit`
- Calculated field: `margin % = profit / revenue`

## Pivot 4: Customer LTV
- Rows: `customer_id` (or `customer_name`)
- Values: Sum of `revenue`, Distinct Count of `order_id`
- Sort by revenue descending

## Pivot 5: Sales Drop Diagnosis
- Rows: `year`, `month_name`
- Columns: `region` (or `category`)
- Values: Sum of `revenue`
- Use conditional formatting to highlight negative month-over-month changes.
