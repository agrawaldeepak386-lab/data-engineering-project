CREATE OR REPLACE TEMP VIEW suppliers_cleaned AS
SELECT
  s.supplier_id,
  s.supplier_name,
  s.contact_email,
  s.country,
  CASE WHEN s.contact_email IS NULL THEN true ELSE false END AS is_email_missing,
  current_timestamp() AS updated_at
FROM (
  SELECT *
  FROM IDENTIFIER(COALESCE(NULLIF(:catalog, ''), 'dev')||'.bronze.suppliers_raw')
  WHERE supplier_id IS NOT NULL          -- drop rows with no primary key at all
) s;
CREATE TABLE IF NOT EXISTS IDENTIFIER(COALESCE(NULLIF(:catalog, ''), 'dev')||'.silver.suppliers_clean') AS
SELECT
  *
FROM suppliers_cleaned;