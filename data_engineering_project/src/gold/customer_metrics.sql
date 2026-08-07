-- KPI 2: Customer Analytics
-- Customer lifetime value (CLV)
-- New vs returning customers
-- Average order value by customer segment
-- Window functions: LAG(), LEAD(), FIRST_VALUE()
create or replace view IDENTIFIER(COALESCE(NULLIF(:catalog, ''), 'dev')||'.gold.customer_metrics') AS
WITH customer_purchases AS (
    SELECT
        customer_id,
        sale_id,
        sale_date,
        sale_amount,
        region
    FROM IDENTIFIER(COALESCE(NULLIF(:catalog, ''), 'dev')||'.silver.sales_clean')
),
customer_metrics AS (
    SELECT
        customer_id,
        COUNT(DISTINCT sale_id) AS total_purchases,
        SUM(sale_amount) AS customer_lifetime_value,
        AVG(sale_amount) AS customer_avg_order_value
    FROM customer_purchases
    GROUP BY customer_id
),

customer_segments AS (
    SELECT
        *,
        CASE
            WHEN total_purchases = 1 THEN 'New Customer'
            ELSE 'Returning Customer'
        END AS customer_type,
        CASE
            WHEN customer_lifetime_value >= 300000 THEN 'High Value'
            WHEN customer_lifetime_value >= 150000 THEN 'Medium Value'
            ELSE 'Low Value'
        END AS value_segment
    FROM customer_metrics
)

SELECT
    cs.customer_id,
    c.name AS customer_name,
    ROUND(cs.customer_lifetime_value,2) AS customer_clv,
    cs.customer_type,
    ROUND(
        SUM(cs.customer_lifetime_value) OVER (PARTITION BY cs.customer_type)
        /
        COUNT(*) OVER (PARTITION BY cs.customer_type),
        2
    ) AS avg_order_value_by_customer_type,
    cs.total_purchases,
    cs.value_segment
FROM customer_segments cs
LEFT JOIN IDENTIFIER(COALESCE(NULLIF(:catalog, ''), 'dev')||'.silver.customers_clean') c
    ON cs.customer_id = c.customer_id
ORDER BY customer_clv DESC;