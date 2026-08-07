-- Add table comments
COMMENT ON TABLE IDENTIFIER(COALESCE(NULLIF(:catalog, ''), 'dev')||'.gold.customer_metrics') IS 
  'Customer analytics and KPIs. Refreshed daily at 6 AM UTC. 
   Owner: Data Engineering Team. Contains PII - restricted access.';


-- Apply tags to tables (tags are created automatically on first use)
ALTER TABLE dev.silver.customers_clean
SET TAGS ('pii_level' = 'high', 'data_classification' = 'confidential');

ALTER TABLE dev.gold.sales_summary 
SET TAGS ('pii_level' = 'none', 'data_classification' = 'internal');

-- Apply tags to columns
ALTER TABLE dev.silver.customers_clean 
ALTER COLUMN email SET TAGS ('pii_level' = 'high');

ALTER TABLE dev.silver.customers_clean 
ALTER COLUMN phone SET TAGS ('pii_level' = 'high');

COMMENT ON TABLE dev.silver.customers_clean IS 
  'Source: dev.bronze.customers_raw | 
   Transformations: Deduplication, NULL handling, SCD Type 1 | 
   Refresh: Every 1 hour | 
   Dependencies: Bronze layer | 
   Downstream: dev.gold.customer_metrics, dashboards';