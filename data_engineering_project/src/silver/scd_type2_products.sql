CREATE OR REPLACE TEMP VIEW products_cleaned AS
SELECT *
FROM (
  SELECT *,
         ROW_NUMBER() OVER (
           PARTITION BY product_id
           ORDER BY product_id
         ) AS rn
  FROM IDENTIFIER(COALESCE(NULLIF(:catalog, ''), 'dev')||'.bronze.products_raw')
  WHERE product_id IS NOT NULL
)
WHERE rn = 1;
CREATE TABLE IF NOT EXISTS IDENTIFIER(COALESCE(NULLIF(:catalog, ''), 'dev')||'.silver.products_scd2') (
  product_id       STRING,
  product_name     STRING,
  category         STRING,
  price            DECIMAL(10,2),
  supplier_id      STRING,
  effective_date   DATE,
  end_date         DATE,
  is_current       BOOLEAN,
  version          INT
);
MERGE INTO IDENTIFIER(COALESCE(NULLIF(:catalog, ''), 'dev')||'.silver.products_scd2') AS t
USING products_cleaned AS s
ON t.product_id = s.product_id AND t.is_current = true
WHEN MATCHED AND (
      t.product_name <> s.product_name
   OR t.price        <> s.price
   OR t.category      <> s.category
   OR t.supplier_id   <> s.supplier_id
) THEN
  UPDATE SET
    t.is_current = false,
    t.end_date   = current_date();
INSERT INTO IDENTIFIER(COALESCE(NULLIF(:catalog, ''), 'dev')||'.silver.products_scd2')
SELECT
  s.product_id,
  s.product_name,
  s.category,
  s.price,
  s.supplier_id,
  current_date() AS effective_date,
  NULL AS end_date,
  true AS is_current,
  COALESCE(
    (SELECT MAX(version) FROM IDENTIFIER(COALESCE(NULLIF(:catalog, ''), 'dev')||'.silver.products_scd2') t
     WHERE t.product_id = s.product_id),
    0
  ) + 1 AS version
FROM products_cleaned s
WHERE NOT EXISTS (
  SELECT 1
  FROM IDENTIFIER(COALESCE(NULLIF(:catalog, ''), 'dev')||'.silver.products_scd2') t
  WHERE t.product_id = s.product_id
    AND t.is_current = true
);