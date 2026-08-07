-- Create a secured view with row-level filtering
CREATE OR REPLACE VIEW IDENTIFIER(COALESCE(NULLIF(:catalog, ''), 'dev')||'.gold.sales_secure') AS
SELECT 
  sale_id,
  customer_id,
  product_id,
  quantity,
  sale_amount,
  sale_date,
  region
FROM IDENTIFIER(COALESCE(NULLIF(:catalog, ''), 'dev')||'.silver.sales_clean');


CREATE OR REPLACE VIEW IDENTIFIER(COALESCE(NULLIF(:catalog, ''), 'dev')||'.gold.customers_masked') AS
SELECT 
  customer_id,
  name,
  -- Full email for data engineers, masked for others
  CASE 
    WHEN is_account_group_member('data_engineers') THEN email
    ELSE CONCAT('***@', SPLIT(email, '@')[1])
  END AS email,
  city,
  state,
  -- Full phone for executives, masked for analysts
  CASE 
    WHEN is_account_group_member('executives') THEN phone
    WHEN is_account_group_member('data_engineers') THEN phone
    ELSE CONCAT('***-***-', RIGHT(phone, 4))
  END AS phone,
  signup_date
FROM IDENTIFIER(COALESCE(NULLIF(:catalog, ''), 'dev')||'.silver.customers_clean');