from pathlib import Path
import json
import pandas as pd
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import FileResponse
from fastapi.staticfiles import StaticFiles


BASE_DIR = Path(__file__).resolve().parents[1]
REPORTS_DIR = BASE_DIR / "reports"
PROCESSED_DIR = BASE_DIR / "data" / "processed"
FRONTEND_DIR = BASE_DIR / "frontend"

app = FastAPI(title="E-Commerce Analytics API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

if FRONTEND_DIR.exists():
    app.mount("/frontend", StaticFiles(directory=str(FRONTEND_DIR)), name="frontend")


def _load_csv(path: Path) -> pd.DataFrame:
    if not path.exists():
        raise HTTPException(status_code=404, detail=f"Missing file: {path.name}")
    return pd.read_csv(path)


@app.get("/api/health")
def health() -> dict:
    return {"status": "ok", "service": "e-commerce-analytics-backend"}


@app.get("/api/kpis")
def kpis() -> dict:
    path = REPORTS_DIR / "kpis.json"
    if not path.exists():
        raise HTTPException(status_code=404, detail="kpis.json not found. Run pipeline first.")
    return json.loads(path.read_text(encoding="utf-8"))


@app.get("/api/monthly-trend")
def monthly_trend() -> list[dict]:
    df = _load_csv(REPORTS_DIR / "monthly_trend.csv")
    return df.to_dict(orient="records")


@app.get("/api/top-products")
def top_products(limit: int = 10) -> list[dict]:
    df = _load_csv(PROCESSED_DIR / "fct_order_items.csv")
    grouped = (
        df.groupby(["product_id", "product_name", "category"], as_index=False)
        .agg(total_revenue=("total_revenue", "sum"), total_units=("quantity", "sum"), total_profit=("line_profit", "sum"))
        .sort_values("total_revenue", ascending=False)
        .head(limit)
    )
    return grouped.to_dict(orient="records")


@app.get("/api/region-sales")
def region_sales() -> list[dict]:
    df = _load_csv(PROCESSED_DIR / "fct_sales.csv")
    grouped = (
        df.groupby("region", as_index=False)
        .agg(revenue=("total_revenue", "sum"), profit=("line_profit", "sum"))
        .sort_values("revenue", ascending=False)
    )
    grouped["margin_pct"] = (grouped["profit"] / grouped["revenue"] * 100).round(2)
    return grouped.to_dict(orient="records")


@app.get("/api/rfm-summary")
def rfm_summary() -> list[dict]:
    df = _load_csv(REPORTS_DIR / "crm_rfm_summary.csv")
    return df.to_dict(orient="records")


@app.get("/api/forecast")
def forecast() -> list[dict]:
    df = _load_csv(REPORTS_DIR / "sales_forecast.csv")
    return df.to_dict(orient="records")


@app.get("/api/recommendations")
def recommendations(limit: int = 50) -> list[dict]:
    df = _load_csv(REPORTS_DIR / "recommendations.csv")
    return df.head(limit).to_dict(orient="records")


@app.get("/")
def root() -> FileResponse:
    index_path = FRONTEND_DIR / "index.html"
    if not index_path.exists():
        raise HTTPException(status_code=404, detail="frontend/index.html not found")
    return FileResponse(index_path)
