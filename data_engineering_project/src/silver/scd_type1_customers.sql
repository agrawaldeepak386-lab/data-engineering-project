CREATE OR REPLACE TEMP VIEW customers_cleaned AS
SELECT *
FROM (
  SELECT *,
         current_timestamp() AS updated_at,
         CASE WHEN email IS NULL THEN true ELSE false END AS is_email_missing,
         ROW_NUMBER() OVER (
           PARTITION BY customer_id
           ORDER BY signup_date DESC
         ) AS rn
  FROM IDENTIFIER(COALESCE(NULLIF(:catalog, ''), 'dev')||'.bronze.customers_raw')
  WHERE customer_id IS NOT NULL
)
WHERE rn = 1;


CREATE TABLE IF NOT EXISTS IDENTIFIER(COALESCE(NULLIF(:catalog, ''), 'dev')||'.silver.customers_clean') AS
SELECT
  customer_id,
  name,
  email,
  city,
  state,
  signup_date,
  phone,
  CASE WHEN email IS NULL THEN true ELSE false END AS is_email_missing,
  current_timestamp() AS updated_at
FROM customers_cleaned;

MERGE INTO  IDENTIFIER(COALESCE(NULLIF(:catalog, ''), 'dev')||'.silver.customers_clean') AS target
USING customers_cleaned AS source
ON target.customer_id = source.customer_id

WHEN MATCHED AND source.updated_at > target.updated_at THEN
  UPDATE SET
    target.name         = source.name,
    target.email        = source.email,
    target.city         = source.city,
    target.state        = source.state,
    target.signup_date  = source.signup_date,
    target.phone        = source.phone,
    target.updated_at   = current_timestamp(),
    target.is_email_missing = source.is_email_missing


WHEN NOT MATCHED THEN
  INSERT (customer_id, name, email, city, state, signup_date, phone, updated_at)
  VALUES (source.customer_id, source.name, source.email, source.city,
          source.state, source.signup_date, source.phone, current_timestamp());


