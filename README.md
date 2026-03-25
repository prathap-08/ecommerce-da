# End-to-End E-Commerce Analytics System

Production-style analytics system built for MNC-level reporting and decision support.

## What This Covers
1. Realistic synthetic source data (`orders`, `customers`, `products`, `payments`) at 100K+ rows.
2. Data cleaning and feature engineering (revenue, CLV, order frequency).
3. Optimized SQL analytics layer (top products, monthly trend, RFM segmentation).
4. Python analytics (trend, profit, retention).
5. Dashboard assets for Power BI/Tableau + Streamlit app.
6. ML enhancements (recommendation engine + sales forecasting).
7. Deployment hooks for MySQL/PostgreSQL.
8. Deliverables folder with reports, chart screenshots, and code.

## Current Data Scale
- `data/raw/orders_raw.csv`: 120,048 rows
- `data/raw/order_items_raw.csv`: 300,532 rows
- `data/raw/payments_raw.csv`: 120,048 rows
- `data/raw/customers_raw.csv`: 20,040 rows
- `data/raw/products_raw.csv`: 610 rows

## Project Structure
- `scripts/generate_enterprise_data.py`: enterprise dataset generator.
- `analytics/etl_pipeline.py`: data cleaning + feature engineering pipeline.
- `analytics/run_analysis.py`: trend/profit/retention analysis + chart outputs.
- `analytics/advanced_models.py`: recommendations + forecast.
- `analytics/generate_executive_report.py`: business-focused insights report.
- `backend/main.py`: FastAPI backend exposing analytics APIs.
- `frontend/`: standalone frontend dashboard (HTML/CSS/JS).
- `sql/postgres_advanced/`: schema, load, and optimized analysis queries.
- `app/streamlit_app.py`: deployed analytics app entrypoint.
- `reports/`: KPI JSON, insights reports, retention/trend/model outputs.
- `dashboard/screenshots/`: chart screenshots for dashboard deliverables.

## Quick Start (Windows PowerShell)
1. Install dependencies (already installed in `.venv`):
	 - `pip install -r requirements.txt`
2. Run full pipeline:
	 - `./scripts/run_full_pipeline.ps1`
3. Start Streamlit dashboard:
	 - `streamlit run app/streamlit_app.py`
4. Start FastAPI backend + frontend:
	 - `./scripts/run_backend.ps1`
	 - Open `http://127.0.0.1:8000`

## Frontend + Backend (New)
### Backend
- Framework: FastAPI
- Entry point: `backend/main.py`
- APIs:
	- `/api/health`
	- `/api/kpis`
	- `/api/monthly-trend`
	- `/api/top-products`
	- `/api/region-sales`
	- `/api/rfm-summary`
	- `/api/forecast`
	- `/api/recommendations`

### Frontend
- Stack: HTML/CSS/JavaScript
- Files:
	- `frontend/index.html`
	- `frontend/styles.css`
	- `frontend/app.js`
- Served by backend at root route `/`.

## Data Processing Features Implemented
- Missing value handling:
	- `customers.city` -> `Unknown`
	- `orders.region` -> `Unknown`
	- `payments.payment_method` -> `Unknown`
- Duplicate handling:
	- de-duplication across customer/product/order/payment primary keys.
- Feature engineering:
	- `total_revenue = quantity * unit_selling_price`
	- Customer Lifetime Value (`lifetime_value`)
	- Order frequency (`order_frequency`)
	- Line profit and order profit

## SQL Layer (Optimized)
Use files in `sql/postgres_advanced/`:
- `schema_postgres_advanced.sql`
- `load_postgres_advanced.sql`
- `analysis_queries_advanced.sql`

Included SQL analytics:
- Top selling products (revenue, units, profit)
- Monthly revenue trend + MoM growth
- RFM customer segmentation with segment labels

## Python Analysis Outputs
Generated in `reports/`:
- `monthly_trend.csv`
- `profit_by_category.csv`
- `customer_retention_cohorts.csv`
- `kpis.json`
- `business_insights_report.md`
- `executive_insights_report.md`
- `recommendations.csv`
- `sales_forecast.csv`

Generated dashboard screenshot assets in `dashboard/screenshots/`:
- `monthly_revenue_trend.png`
- `category_profit.png`
- `retention_curve.png`

## Dashboard (Power BI / Tableau)
Build using:
- `powerbi/enterprise_dashboard_guide.md`
- `powerbi/dashboard_guide.md`
- `powerbi/star_schema_guide.md`

## Deployment and Database Connection
### Load processed data to PostgreSQL/MySQL
Use SQLAlchemy URL format:
- PostgreSQL: `postgresql+psycopg2://user:password@host:5432/dbname`
- MySQL: `mysql+pymysql://user:password@host:3306/dbname`

Command:
- `python scripts/load_to_database.py --database-url "<YOUR_DATABASE_URL>" --if-exists replace`

### Run Streamlit with DB
Set env variable:
- `DATABASE_URL=<YOUR_DATABASE_URL>`

Then run:
- `streamlit run app/streamlit_app.py`

## Business KPI Definitions
- Revenue: sum of delivered order revenue.
- Profit: sum of delivered order profit.
- Profit Margin %: `profit / revenue`.
- CLV: total delivered revenue per customer.
- Order Frequency: delivered order count per customer.

## Notes
- Legacy starter files for smaller sample workflows are preserved.
- MySQL and SQL Server starter SQL files are available under `sql/mysql/` and `sql/sqlserver/`.
