# Enterprise Dashboard Build Guide (Power BI / Tableau)

## Dashboard Pages
1. Executive Overview
- KPI cards: Revenue, Orders, Profit, Margin %, AOV
- Monthly revenue trend with MoM growth labels

2. Region Performance
- Region-wise sales map
- Region profitability and return/cancel rates

3. Product Analytics
- Top products by revenue and profit
- Category contribution and margin waterfall

4. Customer Segmentation
- RFM segment distribution
- LTV by segment and retention trend

5. Forecast and Recommendations
- 6-month sales forecast
- Recommended products for key customer cohorts

## Fields to Use
- Revenue: `fct_orders.order_revenue`
- Profit: `fct_orders.order_profit`
- Quantity: `fct_order_items.quantity`
- Region: `fct_orders.region`
- Category/Product: `fct_order_items.category`, `fct_order_items.product_name`
- Segment/LTV: `dim_customers.segment`, `dim_customers.lifetime_value`

## Suggested DAX (Power BI)
```DAX
Revenue = SUM(fct_orders[order_revenue])
Profit = SUM(fct_orders[order_profit])
Orders = DISTINCTCOUNT(fct_orders[order_id])
Margin % = DIVIDE([Profit], [Revenue])
AOV = DIVIDE([Revenue], [Orders])

Revenue MoM % =
VAR PrevMonth = CALCULATE([Revenue], DATEADD('Date'[Date], -1, MONTH))
RETURN DIVIDE([Revenue] - PrevMonth, PrevMonth)
```

## Screenshot Deliverables
After building visuals, export screenshots and keep them in:
- `dashboard/screenshots/`
