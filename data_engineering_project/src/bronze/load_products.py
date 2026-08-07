import argparse
import pandas as pd
import random

# ---- Parse job parameters ----
parser = argparse.ArgumentParser()
parser.add_argument("--catalog", type=str, default="dev")
args, _ = parser.parse_known_args()

catalog = args.catalog
input_path = f"/Volumes/{catalog}/bronze/raw/"

print(f"Using catalog: {catalog}")
print(f"Writing to: {input_path}")

NUM_PRODUCTS = 500

categories = [
    "Electronics",
    "Clothing",
    "Books",
    "Home",
    "Sports",
    "Beauty",
    "Furniture",
    "Food"
]

product_names = [
    "Laptop","Phone","Tablet","Camera","Keyboard",
    "Mouse","Monitor","Speaker","Printer","Headphones",
    "TV","Watch","Chair","Desk","Sofa",
    "Bag","Bottle","Shoes","Fan","Microwave"
]

products = []

for product_id in range(1, NUM_PRODUCTS + 1):
    products.append({
        "product_id": product_id,
        "product_name": random.choice(product_names),
        "category": random.choice(categories),
        "price": round(random.uniform(100, 5000), 2),
        "supplier_id": random.randint(1, 100)
    })

df = pd.DataFrame(products)

# -------------------------
# NULL Prices
# -------------------------
null_rows = random.sample(range(NUM_PRODUCTS), 20)
for row in null_rows:
    df.loc[row, "price"] = None

# -------------------------
# Duplicate Product IDs
# -------------------------
duplicate_rows = random.sample(range(NUM_PRODUCTS), 15)
for row in duplicate_rows:
    df.loc[row, "product_id"] = random.randint(1, 50)

df = spark.createDataFrame(df)

df.write.mode("overwrite").option("header", True).csv(f"{input_path}/products")