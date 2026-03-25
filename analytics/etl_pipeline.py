from pathlib import Path
import pandas as pd


RAW_DIR = Path("data/raw")
PROCESSED_DIR = Path("data/processed")
PROCESSED_DIR.mkdir(parents=True, exist_ok=True)


def read_raw() -> dict[str, pd.DataFrame]:
    files = {
        "customers": RAW_DIR / "customers_raw.csv",
        "products": RAW_DIR / "products_raw.csv",
        "orders": RAW_DIR / "orders_raw.csv",
        "order_items": RAW_DIR / "order_items_raw.csv",
        "payments": RAW_DIR / "payments_raw.csv",
    }
    return {k: pd.read_csv(v) for k, v in files.items()}


def clean_data(data: dict[str, pd.DataFrame]) -> dict[str, pd.DataFrame]:
    customers = data["customers"].copy()
    products = data["products"].copy()
    orders = data["orders"].copy()
    order_items = data["order_items"].copy()
    payments = data["payments"].copy()

    customers = customers.drop_duplicates(subset=["customer_id"], keep="first")
    products = products.drop_duplicates(subset=["product_id"], keep="first")
    orders = orders.drop_duplicates(subset=["order_id"], keep="first")
    payments = payments.drop_duplicates(subset=["payment_id"], keep="first")
    order_items = order_items.drop_duplicates(subset=["order_id", "line_no", "product_id"], keep="first")

    customers["city"] = customers["city"].fillna("Unknown")
    customers["segment"] = customers["segment"].fillna("Consumer")

    orders["region"] = orders["region"].fillna("Unknown")
    orders["order_status"] = orders["order_status"].fillna("Delivered")

    payments["payment_method"] = payments["payment_method"].fillna("Unknown")
    payments["payment_status"] = payments["payment_status"].fillna("Success")

    customers["signup_date"] = pd.to_datetime(customers["signup_date"])
    orders["order_date"] = pd.to_datetime(orders["order_date"])
    payments["payment_date"] = pd.to_datetime(payments["payment_date"])

    order_items["quantity"] = order_items["quantity"].fillna(1).astype(int)
    order_items["unit_selling_price"] = order_items["unit_selling_price"].fillna(0.0)

    return {
        "customers": customers,
        "products": products,
        "orders": orders,
        "order_items": order_items,
        "payments": payments,
    }


def engineer_features(data: dict[str, pd.DataFrame]) -> dict[str, pd.DataFrame]:
    customers = data["customers"].copy()
    products = data["products"].copy()
    orders = data["orders"].copy()
    order_items = data["order_items"].copy()
    payments = data["payments"].copy()

    # Total Revenue feature at line level.
    order_items["total_revenue"] = order_items["quantity"] * order_items["unit_selling_price"]

    item_enriched = order_items.merge(products[["product_id", "unit_cost", "category", "brand", "product_name"]], on="product_id", how="left")
    item_enriched["line_cost"] = item_enriched["quantity"] * item_enriched["unit_cost"]
    item_enriched["line_profit"] = item_enriched["total_revenue"] - item_enriched["line_cost"]

    order_value = item_enriched.groupby("order_id", as_index=False).agg(
        order_revenue=("total_revenue", "sum"),
        order_profit=("line_profit", "sum"),
        order_items_count=("product_id", "count"),
    )

    orders_enriched = orders.merge(order_value, on="order_id", how="left")

    customer_order_agg = orders_enriched.groupby("customer_id", as_index=False).agg(
        lifetime_value=("order_revenue", "sum"),
        order_frequency=("order_id", "count"),
        avg_order_value=("order_revenue", "mean"),
        total_profit=("order_profit", "sum"),
        first_order_date=("order_date", "min"),
        last_order_date=("order_date", "max"),
    )
    customer_order_agg["customer_tenure_days"] = (
        customer_order_agg["last_order_date"] - customer_order_agg["first_order_date"]
    ).dt.days.clip(lower=1)

    customers_enriched = customers.merge(customer_order_agg, on="customer_id", how="left")
    fill_zero_cols = ["lifetime_value", "order_frequency", "avg_order_value", "total_profit"]
    customers_enriched[fill_zero_cols] = customers_enriched[fill_zero_cols].fillna(0)

    fact_sales = (
        item_enriched
        .merge(orders[["order_id", "order_date", "customer_id", "region", "order_status"]], on="order_id", how="left")
        .merge(customers[["customer_id", "segment", "city"]], on="customer_id", how="left")
    )
    fact_sales["order_month"] = fact_sales["order_date"].dt.to_period("M").astype(str)

    return {
        "dim_customers": customers_enriched,
        "dim_products": products,
        "fct_orders": orders_enriched,
        "fct_order_items": item_enriched,
        "fct_payments": payments,
        "fct_sales": fact_sales,
    }


def save_processed(data: dict[str, pd.DataFrame]) -> None:
    for name, df in data.items():
        df.to_csv(PROCESSED_DIR / f"{name}.csv", index=False)


def main() -> None:
    raw_data = read_raw()
    cleaned = clean_data(raw_data)
    engineered = engineer_features(cleaned)
    save_processed(engineered)

    print("Processed datasets written to data/processed")
    for name, df in engineered.items():
        print(f"{name}.csv rows={len(df):,}")


if __name__ == "__main__":
    main()
