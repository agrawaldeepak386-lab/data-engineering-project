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

NUM_SUPPLIERS = 100

countries = [
    "India", "USA", "Canada", "Germany", "UK",
    "Australia", "Japan", "France", "Singapore", "UAE"
]

suppliers = []

for supplier_id in range(1, NUM_SUPPLIERS + 1):
    suppliers.append({
        "supplier_id": supplier_id,
        "supplier_name": f"Supplier_{supplier_id}",
        "contact_email": f"supplier{supplier_id}@company.com",
        "country": random.choice(countries)
    })

df = pd.DataFrame(suppliers)

# -------------------------
# Data Quality Issue
# NULL contact_email
# -------------------------
null_rows = random.sample(range(NUM_SUPPLIERS), 10)
for row in null_rows:
    df.loc[row, "contact_email"] = None

# Convert pandas DataFrame to Spark DataFrame
df = spark.createDataFrame(df)

df.write.mode("overwrite").option("header", True).csv(f"{input_path}/suppliers")

print(f"Wrote {df.count()} supplier records to {input_path}/suppliers")