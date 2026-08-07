-- KPI 4: Trend Analysis

-- Moving averages (7-day, 30-day)
-- Running totals
-- Cumulative metrics
-- Window functions: SUM() OVER(ORDER BY sale_date ROWS BETWEEN ...)
create or replace view IDENTIFIER(COALESCE(NULLIF(:catalog, ''), 'dev')||'.gold.daily_kpis') AS
WITH daily_sales AS (
  SELECT
    sale_date,
    SUM(sale_amount) AS sale_amount
  FROM IDENTIFIER(COALESCE(NULLIF(:catalog, ''), 'dev')||'.silver.sales_clean')
  GROUP BY sale_date
)
SELECT
  sale_date,
  round(sale_amount,2) AS sale_amount,
  round(SUM(sale_amount) OVER(ORDER BY sale_date ROWS BETWEEN 6 PRECEDING AND CURRENT ROW),2) AS sale_amount_7d,
  round(SUM(sale_amount) OVER(ORDER BY sale_date ROWS BETWEEN 29 PRECEDING AND CURRENT ROW),2) AS sale_amount_30d,
  round(SUM(sale_amount) OVER(ORDER BY sale_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW),2) AS sale_amount_rt,
  round(SUM(sale_amount) OVER(ORDER BY sale_date ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING),2) AS sale_amount_ct
FROM daily_sales
ORDER BY sale_date;