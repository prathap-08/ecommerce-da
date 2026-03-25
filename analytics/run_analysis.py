from pathlib import Path
import json
import pandas as pd
import matplotlib.pyplot as plt


PROCESSED_DIR = Path("data/processed")
REPORTS_DIR = Path("reports")
SCREENSHOT_DIR = Path("dashboard/screenshots")
REPORTS_DIR.mkdir(parents=True, exist_ok=True)
SCREENSHOT_DIR.mkdir(parents=True, exist_ok=True)


def load_data() -> tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame]:
    sales = pd.read_csv(PROCESSED_DIR / "fct_sales.csv", parse_dates=["order_date"])
    orders = pd.read_csv(PROCESSED_DIR / "fct_orders.csv", parse_dates=["order_date"])
    customers = pd.read_csv(PROCESSED_DIR / "dim_customers.csv", parse_dates=["signup_date", "first_order_date", "last_order_date"])
    return sales, orders, customers


def sales_trend_analysis(orders: pd.DataFrame) -> pd.DataFrame:
    delivered = orders[orders["order_status"] == "Delivered"].copy()
    monthly = delivered.resample("MS", on="order_date").agg(
        revenue=("order_revenue", "sum"),
        orders=("order_id", "count"),
        profit=("order_profit", "sum"),
    ).reset_index()
    monthly["mom_growth_pct"] = monthly["revenue"].pct_change() * 100

    plt.figure(figsize=(12, 5))
    plt.plot(monthly["order_date"], monthly["revenue"], marker="o", linewidth=2)
    plt.title("Monthly Revenue Trend")
    plt.xlabel("Month")
    plt.ylabel("Revenue")
    plt.tight_layout()
    plt.savefig(SCREENSHOT_DIR / "monthly_revenue_trend.png", dpi=140)
    plt.close()

    return monthly


def profit_analysis(sales: pd.DataFrame) -> pd.DataFrame:
    cat_profit = sales.groupby("category", as_index=False).agg(
        revenue=("total_revenue", "sum"),
        profit=("line_profit", "sum"),
    )
    cat_profit["profit_margin_pct"] = (cat_profit["profit"] / cat_profit["revenue"]) * 100
    cat_profit = cat_profit.sort_values("profit", ascending=False)

    plt.figure(figsize=(10, 5))
    plt.bar(cat_profit["category"], cat_profit["profit"], color="#2a9d8f")
    plt.title("Category-wise Profit")
    plt.xlabel("Category")
    plt.ylabel("Profit")
    plt.tight_layout()
    plt.savefig(SCREENSHOT_DIR / "category_profit.png", dpi=140)
    plt.close()

    return cat_profit


def customer_retention_analysis(orders: pd.DataFrame) -> pd.DataFrame:
    delivered = orders[orders["order_status"] == "Delivered"].copy()
    delivered["order_month"] = delivered["order_date"].dt.to_period("M").dt.to_timestamp()
    cohorts = delivered.groupby("customer_id")["order_month"].min().rename("cohort_month")
    retention = delivered.join(cohorts, on="customer_id")
    retention["cohort_index"] = (
        (retention["order_month"].dt.year - retention["cohort_month"].dt.year) * 12
        + (retention["order_month"].dt.month - retention["cohort_month"].dt.month)
    )

    cohort_data = retention.groupby(["cohort_month", "cohort_index"])["customer_id"].nunique().reset_index()
    cohort_sizes = cohort_data[cohort_data["cohort_index"] == 0][["cohort_month", "customer_id"]].rename(columns={"customer_id": "cohort_size"})
    cohort_data = cohort_data.merge(cohort_sizes, on="cohort_month", how="left")
    cohort_data["retention_rate"] = cohort_data["customer_id"] / cohort_data["cohort_size"]

    retention_curve = cohort_data[cohort_data["cohort_month"] == cohort_data["cohort_month"].min()].copy()

    plt.figure(figsize=(10, 5))
    plt.plot(retention_curve["cohort_index"], retention_curve["retention_rate"], marker="o", color="#e76f51")
    plt.title("Customer Retention Curve (First Cohort)")
    plt.xlabel("Months Since First Purchase")
    plt.ylabel("Retention Rate")
    plt.tight_layout()
    plt.savefig(SCREENSHOT_DIR / "retention_curve.png", dpi=140)
    plt.close()

    return cohort_data


def export_kpis(orders: pd.DataFrame, sales: pd.DataFrame, customers: pd.DataFrame) -> dict:
    delivered_orders = orders[orders["order_status"] == "Delivered"]
    total_revenue = float(delivered_orders["order_revenue"].sum())
    total_profit = float(delivered_orders["order_profit"].sum())
    total_orders = int(delivered_orders["order_id"].nunique())
    total_customers = int(customers["customer_id"].nunique())
    avg_order_value = total_revenue / total_orders if total_orders else 0.0
    margin_pct = (total_profit / total_revenue * 100) if total_revenue else 0.0

    kpis = {
        "total_revenue": round(total_revenue, 2),
        "total_profit": round(total_profit, 2),
        "profit_margin_pct": round(margin_pct, 2),
        "total_orders": total_orders,
        "total_customers": total_customers,
        "avg_order_value": round(avg_order_value, 2),
        "active_regions": int(sales["region"].nunique()),
    }

    with open(REPORTS_DIR / "kpis.json", "w", encoding="utf-8") as f:
        json.dump(kpis, f, indent=2)

    return kpis


def write_business_report(kpis: dict, monthly: pd.DataFrame, cat_profit: pd.DataFrame, cohort_data: pd.DataFrame) -> None:
    top_month = monthly.sort_values("revenue", ascending=False).iloc[0]
    low_month = monthly.sort_values("revenue", ascending=True).iloc[0]
    top_category = cat_profit.sort_values("profit", ascending=False).iloc[0]
    worst_category = cat_profit.sort_values("profit_margin_pct", ascending=True).iloc[0]

    first_cohort = cohort_data[cohort_data["cohort_month"] == cohort_data["cohort_month"].min()]
    month_3_ret = first_cohort[first_cohort["cohort_index"] == 3]["retention_rate"]
    month_3_ret_val = float(month_3_ret.iloc[0] * 100) if len(month_3_ret) else 0.0

    lines = [
        "# E-Commerce Business Insights Report",
        "",
        "## Executive Summary",
        f"- Revenue reached {kpis['total_revenue']:,} with {kpis['total_orders']:,} successful orders.",
        f"- Profit closed at {kpis['total_profit']:,} with margin {kpis['profit_margin_pct']}%.",
        f"- Average order value is {kpis['avg_order_value']:,} across {kpis['total_customers']:,} customers.",
        "",
        "## Key Findings",
        f"- Peak month: {top_month['order_date'].strftime('%Y-%m')} with revenue {top_month['revenue']:.2f}.",
        f"- Weak month: {low_month['order_date'].strftime('%Y-%m')} with revenue {low_month['revenue']:.2f}.",
        f"- Most profitable category: {top_category['category']} with profit {top_category['profit']:.2f}.",
        f"- Lowest margin category: {worst_category['category']} at {worst_category['profit_margin_pct']:.2f}%.",
        f"- Month-3 retention for first cohort: {month_3_ret_val:.2f}%.",
        "",
        "## Business Recommendations",
        "- Increase ad spend before peak seasonal months (Oct-Dec) and optimize inventory for top categories.",
        "- Improve underperforming category pricing and vendor negotiations to protect margin.",
        "- Launch win-back campaigns for cohorts dropping after month 2 to improve retention.",
    ]

    (REPORTS_DIR / "business_insights_report.md").write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    sales, orders, customers = load_data()
    monthly = sales_trend_analysis(orders)
    cat_profit = profit_analysis(sales)
    cohort_data = customer_retention_analysis(orders)

    monthly.to_csv(REPORTS_DIR / "monthly_trend.csv", index=False)
    cat_profit.to_csv(REPORTS_DIR / "profit_by_category.csv", index=False)
    cohort_data.to_csv(REPORTS_DIR / "customer_retention_cohorts.csv", index=False)

    kpis = export_kpis(orders, sales, customers)
    write_business_report(kpis, monthly, cat_profit, cohort_data)

    print("Analysis completed. Outputs are in reports/ and dashboard/screenshots/")


if __name__ == "__main__":
    main()
