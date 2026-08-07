import argparse
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

# Sample data for realistic generation
first_names = ['John', 'Jane', 'Michael', 'Sarah', 'David', 'Emily', 'Robert', 'Lisa',
               'James', 'Mary', 'William', 'Jennifer', 'Richard', 'Patricia', 'Thomas']
last_names = ['Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller',
              'Davis', 'Rodriguez', 'Martinez', 'Hernandez', 'Lopez', 'Gonzalez', 'Wilson']
cities_states = [
    ('New York', 'NY'), ('Los Angeles', 'CA'), ('Chicago', 'IL'), ('Houston', 'TX'),
    ('Phoenix', 'AZ'), ('Philadelphia', 'PA'), ('San Antonio', 'TX'), ('San Diego', 'CA'),
    ('Dallas', 'TX'), ('San Jose', 'CA'), ('Austin', 'TX'), ('Jacksonville', 'FL'),
    ('San Francisco', 'CA'), ('Seattle', 'WA'), ('Denver', 'CO'), ('Boston', 'MA')
]

# Generate 1200 customer records
customers_data = []
start_date = datetime(2025, 1, 1)
end_date = datetime(2026, 7, 31)

for i in range(1, 1201):
    customer_id = i
    first_name = random.choice(first_names)
    last_name = random.choice(last_names)
    name = f"{first_name} {last_name}"

    email = None if random.random() < 0.12 else f"{first_name.lower()}.{last_name.lower()}{i}@email.com"

    city, state = random.choice(cities_states)

    days_between = (end_date - start_date).days
    random_days = random.randint(0, days_between)
    signup_date = (start_date + timedelta(days=random_days)).strftime('%Y-%m-%d')

    phone = None if random.random() < 0.10 else f"555-{random.randint(1000, 9999)}"

    customers_data.append((customer_id, name, email, city, state, signup_date, phone))

# Add intentional duplicates (~5% duplicate rate)
num_duplicates = 60
for _ in range(num_duplicates):
    duplicate_record = random.choice(customers_data[:1000])
    customers_data.append(duplicate_record)

random.shuffle(customers_data)

print(f"Generated {len(customers_data)} customer records (including {num_duplicates} duplicates)")

df_customers = spark.createDataFrame(
    customers_data,
    ['customer_id', 'name', 'email', 'city', 'state', 'signup_date', 'phone']
)
df_customers.write.mode("overwrite").option("header", True).csv(f"{input_path}/customers")