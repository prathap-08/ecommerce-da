# Power BI Dashboard Guide

## Data Model
- Load `orders`, `products`, `sales` tables.
- Relationships:
  - `orders[order_id]` 1:* `sales[order_id]`
  - `products[product_id]` 1:* `sales[product_id]`
- Create a Date table and relate Date[Date] -> orders[order_date].

## Core DAX Measures
```DAX
Total Revenue = SUM(sales[revenue])

Total Units = SUM(sales[quantity])

Total Orders = DISTINCTCOUNT(orders[order_id])

AOV = DIVIDE([Total Revenue], [Total Orders])

Total Cost = SUMX(sales, sales[quantity] * RELATED(products[unit_cost]))

Total Profit = [Total Revenue] - [Total Cost]

Profit Margin % = DIVIDE([Total Profit], [Total Revenue])

Customer LTV = [Total Revenue]

Revenue MoM % =
VAR PrevMonth = CALCULATE([Total Revenue], DATEADD('Date'[Date], -1, MONTH))
RETURN DIVIDE([Total Revenue] - PrevMonth, PrevMonth)
```

## Page Layout (Single Executive Dashboard)
1. KPI Cards: Revenue, Profit, Margin %, Orders, AOV
2. Monthly trend line: Revenue and MoM %
3. Bar chart: Top 10 products by revenue
4. Map/bar: Revenue by region
5. Table: Top customers by LTV
6. Matrix heatmap: Month x Category revenue

## Suggested Slicers
- Date range
- Region
- Category
- Customer segment (if available)

## Detect Low Months in Dashboard
- Add a conditional color rule on MoM % chart where values < -10% are red.
- Add drill-through page for selected month showing region/category contributors.
