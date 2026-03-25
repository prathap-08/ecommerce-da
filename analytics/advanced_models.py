from pathlib import Path
import pandas as pd
from sklearn.metrics.pairwise import cosine_similarity
from sklearn.preprocessing import MinMaxScaler
from statsmodels.tsa.holtwinters import ExponentialSmoothing


PROCESSED_DIR = Path("data/processed")
REPORTS_DIR = Path("reports")
REPORTS_DIR.mkdir(parents=True, exist_ok=True)


def build_recommendations(top_n: int = 5) -> pd.DataFrame:
    sales = pd.read_csv(PROCESSED_DIR / "fct_sales.csv")
    orders = pd.read_csv(PROCESSED_DIR / "fct_orders.csv")

    delivered_orders = orders.loc[orders["order_status"] == "Delivered", ["order_id", "customer_id"]]
    interactions = sales[["order_id", "product_id", "quantity"]].merge(delivered_orders, on="order_id", how="inner")

    matrix = interactions.pivot_table(
        index="customer_id",
        columns="product_id",
        values="quantity",
        aggfunc="sum",
        fill_value=0,
    )

    if matrix.shape[0] < 2 or matrix.shape[1] < 2:
        return pd.DataFrame(columns=["customer_id", "recommended_product_id", "score"])

    sim = cosine_similarity(matrix.T)
    sim_df = pd.DataFrame(sim, index=matrix.columns, columns=matrix.columns)

    recommendations = []
    for customer_id, row in matrix.iterrows():
        purchased = row[row > 0].index.tolist()
        candidate_scores = {}

        for p in purchased:
            similar = sim_df[p].sort_values(ascending=False).iloc[1:20]
            for candidate, score in similar.items():
                if candidate in purchased:
                    continue
                candidate_scores[candidate] = candidate_scores.get(candidate, 0.0) + float(score)

        top_items = sorted(candidate_scores.items(), key=lambda x: x[1], reverse=True)[:top_n]
        for product_id, score in top_items:
            recommendations.append(
                {
                    "customer_id": customer_id,
                    "recommended_product_id": product_id,
                    "score": round(score, 4),
                }
            )

    rec_df = pd.DataFrame(recommendations)
    rec_df.to_csv(REPORTS_DIR / "recommendations.csv", index=False)
    return rec_df


def forecast_sales(periods: int = 6) -> pd.DataFrame:
    orders = pd.read_csv(PROCESSED_DIR / "fct_orders.csv", parse_dates=["order_date"])
    delivered = orders[orders["order_status"] == "Delivered"].copy()

    monthly = (
        delivered
        .set_index("order_date")
        .resample("MS")["order_revenue"]
        .sum()
        .rename("revenue")
    )

    if len(monthly) < 12:
        future_idx = pd.date_range(monthly.index.max() + pd.offsets.MonthBegin(1), periods=periods, freq="MS")
        forecast_df = pd.DataFrame({"month": future_idx, "forecast_revenue": [monthly.mean()] * periods})
    else:
        model = ExponentialSmoothing(monthly, trend="add", seasonal="add", seasonal_periods=12)
        fitted = model.fit(optimized=True)
        forecast = fitted.forecast(periods)
        forecast_df = pd.DataFrame({"month": forecast.index, "forecast_revenue": forecast.values})

    scaler = MinMaxScaler(feature_range=(0, 1))
    forecast_df["forecast_index"] = scaler.fit_transform(forecast_df[["forecast_revenue"]])
    forecast_df.to_csv(REPORTS_DIR / "sales_forecast.csv", index=False)
    return forecast_df


def main() -> None:
    recs = build_recommendations()
    forecast = forecast_sales()

    print(f"Recommendations rows: {len(recs):,}")
    print(f"Forecast rows: {len(forecast):,}")
    print("Advanced model outputs written to reports/")


if __name__ == "__main__":
    main()
