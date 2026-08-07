-- Gold Layer: Customer Last Purchase Analysis
-- Query to show last purchase date for each customer
-- and identify customers who haven't purchased in 90 days
create or replace view IDENTIFIER(COALESCE(NULLIF(:catalog, ''), 'dev')||'.gold.customer_last_purchase') AS
SELECT 
    c.customer_id,
    c.name AS customer_name,
    c.email,
    c.city,
    c.state,
    c.signup_date,
    s.last_purchase_date,
    s.last_order_id,
    s.last_purchase_amount,
    s.total_orders,
    s.total_lifetime_value,
    DATEDIFF(s.last_purchase_date,c.signup_date) AS days_since_last_purchase,
    CASE 
        WHEN s.last_purchase_date IS NULL THEN 'Never Purchased'
        WHEN DATEDIFF(c.signup_date, s.last_purchase_date) > 180 THEN 'Inactive (180+ days)'
        WHEN DATEDIFF(c.signup_date, s.last_purchase_date) > 90 THEN 'At Risk (90-180 days)'
        WHEN DATEDIFF(c.signup_date, s.last_purchase_date) > 30 THEN 'Declining (30-90 days)'
        ELSE 'Active (0-30 days)'
    END AS customer_activity_status
FROM IDENTIFIER(COALESCE(NULLIF(:catalog, ''), 'dev')||'.silver.customers_clean') c
LEFT JOIN (
    SELECT 
        customer_id,
        MAX(sale_date) AS last_purchase_date,
        MAX_BY(sale_id, sale_date) AS last_order_id,
        MAX_BY(sale_amount, sale_date) AS last_purchase_amount,
        COUNT(DISTINCT sale_id) AS total_orders,
        SUM(sale_amount) AS total_lifetime_value
    FROM IDENTIFIER(COALESCE(NULLIF(:catalog, ''), 'dev')||'.silver.sales_clean')
    WHERE sale_date IS NOT NULL
    GROUP BY customer_id
) s ON c.customer_id = s.customer_id
ORDER BY days_since_last_purchase DESC;