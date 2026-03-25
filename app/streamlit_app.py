import os
from pathlib import Path
import json
import pandas as pd
import plotly.express as px
import streamlit as st
from sqlalchemy import create_engine


st.set_page_config(page_title="E-Commerce Analytics", layout="wide")

PROCESSED_DIR = Path("data/processed")
REPORTS_DIR = Path("reports")


@st.cache_data
def load_local_data():
    sales = pd.read_csv(PROCESSED_DIR / "fct_sales.csv", parse_dates=["order_date"])
    orders = pd.read_csv(PROCESSED_DIR / "fct_orders.csv", parse_dates=["order_date"])
    customers = pd.read_csv(PROCESSED_DIR / "dim_customers.csv")
    products = pd.read_csv(PROCESSED_DIR / "dim_products.csv")
    return sales, orders, customers, products


def load_from_db() -> tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame, pd.DataFrame] | None:
    conn = os.getenv("DATABASE_URL", "")
    if not conn:
        return None
    engine = create_engine(conn)
    sales = pd.read_sql("SELECT * FROM fct_sales", engine, parse_dates=["order_date"])
    orders = pd.read_sql("SELECT * FROM fct_orders", engine, parse_dates=["order_date"])
    customers = pd.read_sql("SELECT * FROM dim_customers", engine)
    products = pd.read_sql("SELECT * FROM dim_products", engine)
    return sales, orders, customers, products


def kpi_cards(orders: pd.DataFrame):
    delivered = orders[orders["order_status"] == "Delivered"]
    revenue = delivered["order_revenue"].sum()
    orders_count = delivered["order_id"].nunique()
    profit = delivered["order_profit"].sum()

    col1, col2, col3 = st.columns(3)
    col1.metric("Revenue", f"{revenue:,.0f}")
    col2.metric("Orders", f"{orders_count:,}")
    col3.metric("Profit", f"{profit:,.0f}")


def region_map(sales: pd.DataFrame):
    coords = {
        "North": (28.6139, 77.2090),
        "South": (12.9716, 77.5946),
        "East": (22.5726, 88.3639),
        "West": (19.0760, 72.8777),
        "Central": (23.2599, 77.4126),
        "Unknown": (21.1458, 79.0882),
    }
    region_sales = sales.groupby("region", as_index=False)["total_revenue"].sum()
    region_sales[["lat", "lon"]] = region_sales["region"].apply(lambda r: pd.Series(coords.get(r, (21.1458, 79.0882))))

    fig = px.scatter_geo(
        region_sales,
        lat="lat",
        lon="lon",
        size="total_revenue",
        color="total_revenue",
        hover_name="region",
        scope="asia",
        title="Region-wise Sales Map",
    )
    st.plotly_chart(fig, use_container_width=True)


def product_performance(sales: pd.DataFrame):
    top_products = (
        sales.groupby("product_name", as_index=False)["total_revenue"]
        .sum()
        .sort_values("total_revenue", ascending=False)
        .head(10)
    )
    fig = px.bar(top_products, x="product_name", y="total_revenue", title="Top 10 Products by Revenue")
    st.plotly_chart(fig, use_container_width=True)


def customer_segmentation(customers: pd.DataFrame):
    seg = customers.groupby("segment", as_index=False).agg(
        customers=("customer_id", "count"),
        avg_ltv=("lifetime_value", "mean"),
    )
    fig = px.pie(seg, names="segment", values="customers", title="Customer Segmentation")
    st.plotly_chart(fig, use_container_width=True)


st.title("End-to-End E-Commerce Analytics Dashboard")

source = st.sidebar.radio("Data Source", ["Processed CSV", "Database"], index=0)
if source == "Database":
    data = load_from_db()
    if data is None:
        st.warning("DATABASE_URL not set. Falling back to processed CSV.")
        data = load_local_data()
else:
    data = load_local_data()

sales_df, orders_df, customers_df, products_df = data

kpi_cards(orders_df)

left, right = st.columns(2)
with left:
    region_map(sales_df)
with right:
    product_performance(sales_df)

customer_segmentation(customers_df)

st.subheader("Model Outputs")
if (REPORTS_DIR / "sales_forecast.csv").exists():
    forecast = pd.read_csv(REPORTS_DIR / "sales_forecast.csv")
    st.dataframe(forecast)

if (REPORTS_DIR / "recommendations.csv").exists():
    rec = pd.read_csv(REPORTS_DIR / "recommendations.csv").head(20)
    st.dataframe(rec)

if (REPORTS_DIR / "kpis.json").exists():
    st.code(json.dumps(json.loads((REPORTS_DIR / "kpis.json").read_text(encoding="utf-8")), indent=2), language="json")
