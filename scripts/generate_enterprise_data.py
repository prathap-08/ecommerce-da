import argparse
from pathlib import Path
import numpy as np
import pandas as pd


def weighted_choice(rng: np.random.Generator, values, probs, size):
    probs = np.array(probs, dtype=float)
    probs = probs / probs.sum()
    return rng.choice(values, p=probs, size=size)


def build_customers(rng: np.random.Generator, n_customers: int) -> pd.DataFrame:
    first_names = [
        "Aarav", "Vivaan", "Diya", "Isha", "Kabir", "Meera", "Rohan", "Anaya", "Arjun", "Kiara",
        "Neha", "Rahul", "Saanvi", "Aditya", "Nitya", "Varun", "Riya", "Tanvi", "Nikhil", "Pooja",
    ]
    last_names = [
        "Sharma", "Verma", "Patel", "Singh", "Khan", "Iyer", "Gupta", "Nair", "Reddy", "Jain",
        "Mehta", "Das", "Bose", "Malhotra", "Kulkarni", "Yadav", "Chopra", "Roy", "Bhat", "Saxena",
    ]
    regions = ["North", "South", "East", "West", "Central"]
    cities = {
        "North": ["Delhi", "Chandigarh", "Jaipur"],
        "South": ["Bengaluru", "Chennai", "Hyderabad"],
        "East": ["Kolkata", "Bhubaneswar", "Patna"],
        "West": ["Mumbai", "Pune", "Ahmedabad"],
        "Central": ["Bhopal", "Nagpur", "Indore"],
    }

    customer_ids = [f"C{i:06d}" for i in range(1, n_customers + 1)]
    region_values = weighted_choice(rng, regions, [0.22, 0.24, 0.18, 0.24, 0.12], n_customers)
    signup_dates = pd.to_datetime("2022-01-01") + pd.to_timedelta(rng.integers(0, 1200, size=n_customers), unit="D")

    rows = []
    for i, cid in enumerate(customer_ids):
        region = region_values[i]
        rows.append(
            {
                "customer_id": cid,
                "customer_name": f"{rng.choice(first_names)} {rng.choice(last_names)}",
                "email": f"{cid.lower()}@mail.com",
                "region": region,
                "city": rng.choice(cities[region]),
                "signup_date": signup_dates[i].date().isoformat(),
                "segment": rng.choice(["Consumer", "Corporate", "Home Office"], p=[0.68, 0.20, 0.12]),
            }
        )

    customers = pd.DataFrame(rows)

    # Inject realistic missing values and duplicate rows for ETL exercise.
    miss_idx = rng.choice(customers.index, size=max(50, n_customers // 200), replace=False)
    customers.loc[miss_idx, "city"] = None
    dup_rows = customers.sample(n=max(20, n_customers // 500), random_state=42)
    customers = pd.concat([customers, dup_rows], ignore_index=True)
    return customers


def build_products(rng: np.random.Generator, n_products: int) -> pd.DataFrame:
    categories = {
        "Electronics": ["Earbuds", "Smartphone", "Speaker", "Laptop", "Smartwatch", "Router"],
        "Fashion": ["T-Shirt", "Jacket", "Shoes", "Watch", "Sunglasses", "Shirt"],
        "Home": ["Mixer", "Vacuum", "Bottle", "Bedsheet", "Lamp", "Storage Box"],
        "Beauty": ["Serum", "Dryer", "Perfume", "Lipstick", "Lotion", "Trimmer"],
        "Sports": ["Yoga Mat", "Dumbbell", "Cricket Bat", "Football", "Racket", "Gloves"],
    }
    category_names = list(categories.keys())

    rows = []
    for i in range(1, n_products + 1):
        category = rng.choice(category_names, p=[0.24, 0.22, 0.20, 0.16, 0.18])
        product_stub = rng.choice(categories[category])
        product_name = f"{category[:3].upper()}-{product_stub}-{i:04d}"

        base_price = {
            "Electronics": rng.uniform(2500, 50000),
            "Fashion": rng.uniform(500, 7000),
            "Home": rng.uniform(300, 12000),
            "Beauty": rng.uniform(200, 5000),
            "Sports": rng.uniform(350, 15000),
        }[category]

        unit_price = round(float(base_price), 2)
        unit_cost = round(unit_price * float(rng.uniform(0.45, 0.78)), 2)

        rows.append(
            {
                "product_id": f"P{i:05d}",
                "product_name": product_name,
                "category": category,
                "brand": rng.choice(["Alpha", "Nova", "Prime", "Urban", "Zen", "Eco"]),
                "unit_price": unit_price,
                "unit_cost": unit_cost,
            }
        )

    products = pd.DataFrame(rows)
    dup_rows = products.sample(n=max(10, n_products // 200), random_state=99)
    products = pd.concat([products, dup_rows], ignore_index=True)
    return products


def build_orders_payments_items(
    rng: np.random.Generator,
    n_orders: int,
    customers: pd.DataFrame,
    products: pd.DataFrame,
) -> tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame]:
    customer_ids = customers["customer_id"].drop_duplicates().to_numpy()
    product_ids = products["product_id"].drop_duplicates().to_numpy()

    regions = customers.drop_duplicates("customer_id").set_index("customer_id")["region"].to_dict()

    start_date = pd.Timestamp("2024-01-01")
    end_date = pd.Timestamp("2025-12-31")
    total_days = (end_date - start_date).days + 1

    seasonality = {
        1: 0.88, 2: 0.86, 3: 0.93, 4: 0.99, 5: 1.03, 6: 1.06,
        7: 0.97, 8: 1.01, 9: 1.08, 10: 1.16, 11: 1.30, 12: 1.36,
    }

    unit_price_map = products.drop_duplicates("product_id").set_index("product_id")["unit_price"].to_dict()

    orders_rows = []
    payments_rows = []
    items_rows = []

    for i in range(1, n_orders + 1):
        order_id = f"O{i:07d}"
        customer_id = rng.choice(customer_ids)

        picked_date = None
        for _ in range(8):
            candidate = start_date + pd.to_timedelta(int(rng.integers(0, total_days)), unit="D")
            if rng.random() <= min(seasonality[int(candidate.month)] / 1.4, 1.0):
                picked_date = candidate
                break
        if picked_date is None:
            picked_date = start_date + pd.to_timedelta(int(rng.integers(0, total_days)), unit="D")

        region = regions.get(customer_id, "Central")
        order_status = rng.choice(["Delivered", "Returned", "Cancelled"], p=[0.91, 0.06, 0.03])

        orders_rows.append(
            {
                "order_id": order_id,
                "order_date": picked_date.date().isoformat(),
                "customer_id": customer_id,
                "region": region,
                "order_status": order_status,
            }
        )

        n_lines = int(rng.integers(1, 5))
        line_products = rng.choice(product_ids, size=n_lines, replace=False)
        order_total = 0.0

        for line_no, product_id in enumerate(line_products, start=1):
            qty = int(rng.integers(1, 6))
            base_price = float(unit_price_map[product_id])

            if picked_date.month in [1, 7]:
                discount = float(rng.uniform(0.08, 0.26))
            elif picked_date.month in [11, 12]:
                discount = float(rng.uniform(0.00, 0.09))
            else:
                discount = float(rng.uniform(0.02, 0.15))

            unit_selling_price = round(base_price * (1 - discount), 2)
            line_revenue = round(unit_selling_price * qty, 2)
            order_total += line_revenue

            items_rows.append(
                {
                    "order_id": order_id,
                    "line_no": line_no,
                    "product_id": product_id,
                    "quantity": qty,
                    "unit_selling_price": unit_selling_price,
                    "discount_pct": round(discount * 100, 2),
                    "line_revenue": line_revenue,
                }
            )

        payments_rows.append(
            {
                "payment_id": f"PAY{i:08d}",
                "order_id": order_id,
                "payment_date": (picked_date + pd.to_timedelta(int(rng.integers(0, 3)), unit="D")).date().isoformat(),
                "payment_method": rng.choice(["UPI", "Card", "NetBanking", "COD", "Wallet"], p=[0.33, 0.30, 0.14, 0.15, 0.08]),
                "payment_status": "Success" if order_status != "Cancelled" else "Failed",
                "amount": round(order_total if order_status != "Cancelled" else 0.0, 2),
            }
        )

    orders = pd.DataFrame(orders_rows)
    payments = pd.DataFrame(payments_rows)
    order_items = pd.DataFrame(items_rows)

    # Inject missing values and duplicates for ETL tasks.
    miss_order_idx = rng.choice(orders.index, size=max(100, n_orders // 1000), replace=False)
    orders.loc[miss_order_idx, "region"] = None

    miss_pay_idx = rng.choice(payments.index, size=max(100, n_orders // 1200), replace=False)
    payments.loc[miss_pay_idx, "payment_method"] = None

    orders = pd.concat([orders, orders.sample(n=max(40, n_orders // 2500), random_state=7)], ignore_index=True)
    payments = pd.concat([payments, payments.sample(n=max(40, n_orders // 2500), random_state=9)], ignore_index=True)

    return orders, order_items, payments


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate enterprise-scale e-commerce synthetic dataset")
    parser.add_argument("--rows", type=int, default=120_000, help="Number of orders to generate (default: 120000)")
    parser.add_argument("--customers", type=int, default=20_000, help="Number of customers (default: 20000)")
    parser.add_argument("--products", type=int, default=600, help="Number of products (default: 600)")
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument("--output", type=str, default="data/raw")
    args = parser.parse_args()

    rng = np.random.default_rng(args.seed)
    output_dir = Path(args.output)
    output_dir.mkdir(parents=True, exist_ok=True)

    customers = build_customers(rng, args.customers)
    products = build_products(rng, args.products)
    orders, order_items, payments = build_orders_payments_items(rng, args.rows, customers, products)

    customers.to_csv(output_dir / "customers_raw.csv", index=False)
    products.to_csv(output_dir / "products_raw.csv", index=False)
    orders.to_csv(output_dir / "orders_raw.csv", index=False)
    order_items.to_csv(output_dir / "order_items_raw.csv", index=False)
    payments.to_csv(output_dir / "payments_raw.csv", index=False)

    print("Generated enterprise raw dataset")
    print(f"customers_raw.csv rows={len(customers):,}")
    print(f"products_raw.csv rows={len(products):,}")
    print(f"orders_raw.csv rows={len(orders):,}")
    print(f"order_items_raw.csv rows={len(order_items):,}")
    print(f"payments_raw.csv rows={len(payments):,}")


if __name__ == "__main__":
    main()
