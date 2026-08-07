--  KPI 1: Sales Performance Metrics
--  Total revenue by region, product category, time period
--  Year-over-year growth rates
create or replace view IDENTIFIER(COALESCE(NULLIF(:catalog, ''), 'dev')||'.gold.sales_summary') as (
with yearly_revenue as (
  select
    s.region,
    p.category,
    year(s.sale_date) as year,
    sum(s.sale_amount) as total_revenue
  from  IDENTIFIER(COALESCE(NULLIF(:catalog, ''), 'dev')||'.silver.sales_clean') s
  inner join IDENTIFIER(COALESCE(NULLIF(:catalog, ''), 'dev')||'.silver.products_scd2') p
    on cast(s.product_id as string) = p.product_id
  group by s.region, p.category, year(s.sale_date)
  order by s.region, p.category, year(s.sale_date)
)

select
  region,
  category,
  year,
  round(total_revenue, 1) as total_revenue,
  round(
    100 * (total_revenue - lag(total_revenue) over (partition by region, category order by year))
    / lag(total_revenue) over (partition by region, category order by year), 2
  ) as yoy_growth_pct
from yearly_revenue
order by region, category, year);
-- -- select * from dev.gold.sales_summary

