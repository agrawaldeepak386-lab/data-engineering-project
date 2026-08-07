CREATE OR REPLACE TEMP VIEW sales_cleaned AS
SELECT
  s.sale_id,
  s.customer_id,
  s.product_id,
  s.quantity,
  s.sale_amount,
  s.sale_date,
  s.region,
  current_timestamp() AS updated_at
FROM (
  SELECT *,
         ROW_NUMBER() OVER (
           PARTITION BY sale_id
           ORDER BY sale_date DESC
         ) AS rn
  FROM IDENTIFIER(COALESCE(NULLIF(:catalog, ''), 'dev')||'.bronze.sales_raw')
  WHERE quantity IS NOT NULL        
) s;
CREATE TABLE IF NOT EXISTS IDENTIFIER(COALESCE(NULLIF(:catalog, ''), 'dev')||'.silver.sales_clean') AS
SELECT
  *
FROM sales_cleaned;