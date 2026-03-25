import argparse
from pathlib import Path
import pandas as pd
from sqlalchemy import create_engine


PROCESSED_DIR = Path("data/processed")


def main() -> None:
    parser = argparse.ArgumentParser(description="Load processed datasets into PostgreSQL/MySQL")
    parser.add_argument("--database-url", required=True, help="SQLAlchemy URL, e.g. postgresql+psycopg2://user:pass@host/db")
    parser.add_argument("--if-exists", default="replace", choices=["replace", "append"])
    args = parser.parse_args()

    engine = create_engine(args.database_url)

    table_map = {
        "dim_customers": "dim_customers",
        "dim_products": "dim_products",
        "fct_orders": "fct_orders",
        "fct_order_items": "fct_order_items",
        "fct_payments": "fct_payments",
        "fct_sales": "fct_sales",
    }

    for file_stem, table_name in table_map.items():
        csv_path = PROCESSED_DIR / f"{file_stem}.csv"
        df = pd.read_csv(csv_path)
        df.to_sql(table_name, con=engine, if_exists=args.if_exists, index=False, method="multi", chunksize=5000)
        print(f"Loaded {table_name}: {len(df):,} rows")

    print("Database load complete")


if __name__ == "__main__":
    main()
