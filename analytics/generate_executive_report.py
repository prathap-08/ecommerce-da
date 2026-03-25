from pathlib import Path
import json
import pandas as pd


REPORTS_DIR = Path("reports")
PROCESSED_DIR = Path("data/processed")


def main() -> None:
    kpis = json.loads((REPORTS_DIR / "kpis.json").read_text(encoding="utf-8"))
    monthly = pd.read_csv(REPORTS_DIR / "monthly_trend.csv", parse_dates=["order_date"])
    profit_by_category = pd.read_csv(REPORTS_DIR / "profit_by_category.csv")
    forecast = pd.read_csv(REPORTS_DIR / "sales_forecast.csv", parse_dates=["month"])
    retention = pd.read_csv(REPORTS_DIR / "customer_retention_cohorts.csv", parse_dates=["cohort_month"])
    sales = pd.read_csv(PROCESSED_DIR / "fct_sales.csv")

    peak = monthly.sort_values("revenue", ascending=False).iloc[0]
    trough = monthly.sort_values("revenue", ascending=True).iloc[0]

    regions = sales.groupby("region", as_index=False).agg(
        revenue=("total_revenue", "sum"),
        profit=("line_profit", "sum"),
    )
    regions["margin_pct"] = (regions["profit"] / regions["revenue"]) * 100
    top_region = regions.sort_values("revenue", ascending=False).iloc[0]
    low_region = regions.sort_values("revenue", ascending=True).iloc[0]

    top_category = profit_by_category.sort_values("profit", ascending=False).iloc[0]
    low_margin_category = profit_by_category.sort_values("profit_margin_pct", ascending=True).iloc[0]

    first_cohort = retention[retention["cohort_month"] == retention["cohort_month"].min()]
    m1 = first_cohort[first_cohort["cohort_index"] == 1]["retention_rate"]
    m3 = first_cohort[first_cohort["cohort_index"] == 3]["retention_rate"]
    m6 = first_cohort[first_cohort["cohort_index"] == 6]["retention_rate"]

    def pct(series: pd.Series) -> float:
        return float(series.iloc[0] * 100) if len(series) else 0.0

    avg_forecast = float(forecast["forecast_revenue"].mean())
    max_forecast = forecast.sort_values("forecast_revenue", ascending=False).iloc[0]

    lines = [
        "# Executive Business Insights (MNC Style)",
        "",
        "## 1) Executive KPI Snapshot",
        f"- Revenue: {kpis['total_revenue']:,.2f}",
        f"- Profit: {kpis['total_profit']:,.2f}",
        f"- Profit Margin: {kpis['profit_margin_pct']:.2f}%",
        f"- Delivered Orders: {kpis['total_orders']:,}",
        f"- Average Order Value: {kpis['avg_order_value']:,.2f}",
        "",
        "## 2) Demand Pattern and Seasonality",
        f"- Peak revenue month: {peak['order_date'].strftime('%Y-%m')} ({peak['revenue']:,.2f}).",
        f"- Lowest revenue month: {trough['order_date'].strftime('%Y-%m')} ({trough['revenue']:,.2f}).",
        "- Clear year-end uplift indicates strong festive/holiday demand concentration in Q4.",
        "",
        "## 3) Region Performance",
        f"- Top revenue region: {top_region['region']} ({top_region['revenue']:,.2f}, margin {top_region['margin_pct']:.2f}%).",
        f"- Lowest revenue region: {low_region['region']} ({low_region['revenue']:,.2f}).",
        "- Recommendation: prioritize inventory and paid campaigns in high-revenue regions while improving delivery SLA and assortment in weaker regions.",
        "",
        "## 4) Product and Margin Insights",
        f"- Most profitable category: {top_category['category']} ({top_category['profit']:,.2f} profit).",
        f"- Lowest margin category: {low_margin_category['category']} ({low_margin_category['profit_margin_pct']:.2f}% margin).",
        "- Recommendation: renegotiate supplier cost or reduce discount depth in low-margin categories.",
        "",
        "## 5) Customer Retention Health",
        f"- Cohort Month-1 retention: {pct(m1):.2f}%",
        f"- Cohort Month-3 retention: {pct(m3):.2f}%",
        f"- Cohort Month-6 retention: {pct(m6):.2f}%",
        "- Recommendation: launch post-purchase lifecycle journeys (D+7, D+30) with category cross-sell nudges.",
        "",
        "## 6) Forward-Looking Forecast",
        f"- Next 6-month average forecast revenue: {avg_forecast:,.2f}",
        f"- Forecasted peak month: {max_forecast['month'].strftime('%Y-%m')} ({max_forecast['forecast_revenue']:,.2f}).",
        "- Recommendation: lock procurement and warehousing capacity at least 6-8 weeks before projected peak.",
        "",
        "## 7) Strategic Actions for Leadership",
        "- Build category-level margin guardrails to prevent discount-led profit erosion.",
        "- Focus retention on mid-value cohorts with high repeat potential, not only top spenders.",
        "- Use recommendation outputs in CRM campaigns to lift average basket size.",
        "- Track weekly leading indicators: orders, conversion, AOV, and return rate by region/category.",
    ]

    (REPORTS_DIR / "executive_insights_report.md").write_text("\n".join(lines), encoding="utf-8")
    print("Generated reports/executive_insights_report.md")


if __name__ == "__main__":
    main()
