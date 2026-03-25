from pathlib import Path
import pandas as pd


PROCESSED_DIR = Path("data/processed")
REPORTS_DIR = Path("reports")
REPORTS_DIR.mkdir(parents=True, exist_ok=True)

REFERENCE_DATE = pd.Timestamp("2026-01-01")


def score_rfm(df: pd.DataFrame) -> pd.DataFrame:
    df = df.copy()
    df["r_score"] = pd.qcut(df["recency_days"].rank(method="first"), 5, labels=[5, 4, 3, 2, 1]).astype(int)
    df["f_score"] = pd.qcut(df["frequency"].rank(method="first"), 5, labels=[1, 2, 3, 4, 5]).astype(int)
    df["m_score"] = pd.qcut(df["monetary"].rank(method="first"), 5, labels=[1, 2, 3, 4, 5]).astype(int)
    df["rfm_code"] = df["r_score"].astype(str) + df["f_score"].astype(str) + df["m_score"].astype(str)

    def segment(row: pd.Series) -> str:
        r, f, m = row["r_score"], row["f_score"], row["m_score"]
        if r >= 4 and f >= 4 and m >= 4:
            return "Champions"
        if r >= 4 and f >= 3:
            return "Loyal Customers"
        if r >= 3 and f >= 2 and m >= 2:
            return "Potential Loyalists"
        if r <= 2 and f >= 4:
            return "At Risk"
        if r == 1 and f <= 2:
            return "Lost"
        return "Need Attention"

    df["segment"] = df.apply(segment, axis=1)
    return df


def add_crm_actions(df: pd.DataFrame) -> pd.DataFrame:
    action_map = {
        "Champions": "VIP early access, premium cross-sell bundle, referral rewards",
        "Loyal Customers": "Loyalty points booster, subscription offer, category cross-sell",
        "Potential Loyalists": "Welcome-back coupon, personalized recommendations, reorder reminders",
        "At Risk": "Urgent win-back campaign, targeted discount, category-specific offers",
        "Lost": "Reactivation drip, deep-discount trigger, exit survey",
        "Need Attention": "Behavioral nudges, limited-time offers, personalized content",
    }
    priority_map = {
        "Champions": "P1",
        "Loyal Customers": "P1",
        "Potential Loyalists": "P2",
        "At Risk": "P1",
        "Lost": "P2",
        "Need Attention": "P3",
    }

    df = df.copy()
    df["crm_action"] = df["segment"].map(action_map)
    df["priority"] = df["segment"].map(priority_map)
    return df


def main() -> None:
    orders = pd.read_csv(PROCESSED_DIR / "fct_orders.csv", parse_dates=["order_date"])
    customers = pd.read_csv(PROCESSED_DIR / "dim_customers.csv")

    delivered = orders[orders["order_status"] == "Delivered"].copy()

    base = delivered.groupby("customer_id", as_index=False).agg(
        last_order_date=("order_date", "max"),
        frequency=("order_id", "nunique"),
        monetary=("order_revenue", "sum"),
    )
    base["recency_days"] = (REFERENCE_DATE - base["last_order_date"]).dt.days.astype(int)

    scored = score_rfm(base)
    scored = add_crm_actions(scored)

    scored = scored.merge(
        customers[["customer_id", "customer_name", "email", "region", "segment"]],
        on="customer_id",
        how="left",
        suffixes=("", "_customer"),
    )

    scored = scored.rename(columns={"segment_customer": "customer_segment", "segment": "rfm_segment"})

    crm_cols = [
        "customer_id",
        "customer_name",
        "email",
        "region",
        "customer_segment",
        "last_order_date",
        "recency_days",
        "frequency",
        "monetary",
        "r_score",
        "f_score",
        "m_score",
        "rfm_code",
        "rfm_segment",
        "priority",
        "crm_action",
    ]
    crm_df = scored[crm_cols].sort_values(["priority", "monetary"], ascending=[True, False])

    crm_df.to_csv(REPORTS_DIR / "crm_rfm_export.csv", index=False)

    summary = crm_df.groupby("rfm_segment", as_index=False).agg(
        customers=("customer_id", "nunique"),
        revenue=("monetary", "sum"),
        avg_recency_days=("recency_days", "mean"),
    ).sort_values("revenue", ascending=False)
    summary.to_csv(REPORTS_DIR / "crm_rfm_summary.csv", index=False)

    print(f"Generated {REPORTS_DIR / 'crm_rfm_export.csv'} rows={len(crm_df):,}")
    print(f"Generated {REPORTS_DIR / 'crm_rfm_summary.csv'} rows={len(summary):,}")


if __name__ == "__main__":
    main()
