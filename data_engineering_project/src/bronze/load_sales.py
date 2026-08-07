import argparse
import pandas as pd
import random
from datetime import datetime, timedelta

# ---- Parse job parameters ----
parser = argparse.ArgumentParser()
parser.add_argument("--catalog", type=str, default="dev")
args, _ = parser.parse_known_args()

catalog = args.catalog
input_path = f"/Volumes/{catalog}/bronze/raw/"

print(f"Using catalog: {catalog}")
print(f"Writing to: {input_path}")

NUM_SALES = 5000

regions = [
    "North",
    "South",
    "East",
    "West",
    "Central"
]

sales = []

start_date = datetime(2025, 1, 1)

for sale_id in range(1, NUM_SALES + 1):
    customer_id = random.randint(1, 500)
    product_id = random.randint(1, 500)
    quantity = random.randint(1, 10)
    unit_price = round(random.uniform(100, 5000), 2)
    sale_amount = round(quantity * unit_price, 2)
    sale_date = start_date + timedelta(days=random.randint(0, 575))

    sales.append({
        "sale_id": sale_id,
        "customer_id": customer_id,
        "product_id": product_id,
        "quantity": quantity,
        "sale_amount": sale_amount,
        "sale_date": sale_date.strftime("%Y-%m-%d"),
        "region": random.choice(regions)
    })

df = pd.DataFrame(sales)

# -------------------------
# NULL Quantities
# -------------------------
null_rows = random.sample(range(NUM_SALES), 100)
for row in null_rows:
    df.loc[row, "quantity"] = None

# -------------------------
# Orphan Customer IDs
# -------------------------
orphan_customer_rows = random.sample(range(NUM_SALES), 50)
for row in orphan_customer_rows:
    df.loc[row, "customer_id"] = random.randint(501, 550)

# -------------------------
# Orphan Product IDs
# -------------------------
orphan_product_rows = random.sample(range(NUM_SALES), 50)
for row in orphan_product_rows:
    df.loc[row, "product_id"] = random.randint(501, 550)

df = spark.createDataFrame(df)

df.write.mode("overwrite").option("header", True).csv(f"{input_path}/sales")

print(f"Wrote {df.count()} sales records to {input_path}/sales")