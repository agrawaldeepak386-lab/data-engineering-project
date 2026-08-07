-- KPI 3: Product Performance

-- Best-selling products by category
-- Product price changes over time (using SCD Type 2 history)
-- Supplier performance metrics
-- Window functions: SUM() OVER(), AVG() OVER(), PERCENT_RANK()
create or replace view IDENTIFIER(COALESCE(NULLIF(:catalog, ''), 'dev')||'.gold.product_analytics') AS
WITH product_sales AS (
    SELECT
        s.product_id,
        SUM(s.quantity) AS total_quantity_sold,
        SUM(s.sale_amount) AS total_revenue,
        COUNT(DISTINCT s.sale_id) AS total_orders
    FROM IDENTIFIER(COALESCE(NULLIF(:catalog, ''), 'dev')||'.silver.sales_clean') s
    GROUP BY s.product_id
),

category_rank AS (
    SELECT
        p.product_id,
        p.product_name,
        p.category,
        ps.total_quantity_sold,
        ps.total_revenue,
        ps.total_orders,
        RANK() OVER (
            PARTITION BY p.category
            ORDER BY ps.total_quantity_sold DESC
        ) AS category_rank
    FROM product_sales ps
    JOIN IDENTIFIER(COALESCE(NULLIF(:catalog, ''), 'dev')||'.silver.products_scd2') p
        ON ps.product_id = p.product_id
       AND p.is_current = TRUE
),

price_history AS (
    SELECT
        product_id,
        product_name,
        price AS current_price,
       effective_date,
       end_date,
        LAG(price) OVER (
            PARTITION BY product_id
            ORDER BY effective_date
        ) AS previous_price
    FROM IDENTIFIER(COALESCE(NULLIF(:catalog, ''), 'dev')||'.silver.products_scd2')
),

supplier_metrics AS (
    SELECT
        p.supplier_id,
        COUNT(DISTINCT p.product_id) AS total_products,
        SUM(ps.total_quantity_sold) AS units_sold,
        SUM(ps.total_revenue) AS supplier_revenue,
        AVG(ps.total_revenue) AS avg_revenue_per_product
    FROM IDENTIFIER(COALESCE(NULLIF(:catalog, ''), 'dev')||'.silver.products_scd2') p
    LEFT JOIN product_sales ps
        ON p.product_id = ps.product_id
    WHERE p.is_current = TRUE
    GROUP BY p.supplier_id
)

SELECT
    cr.product_id,
    cr.product_name,
    cr.category,
    cr.total_quantity_sold,
    round(cr.total_revenue,2) As total_revenue, 
    cr.total_orders,
    cr.category_rank,

    ph.previous_price,
    ph.current_price,
    (ph.current_price - ph.previous_price) AS price_change,
    ph.effective_date,
    ph.end_date,

    sm.supplier_id,
    sp.supplier_name,
    sm.total_products,
    sm.units_sold,
    round(sm.supplier_revenue,2) As supplier_revenue,
    round(sm.avg_revenue_per_product,2)as avg_revenue_per_product

FROM category_rank cr

LEFT JOIN (
    SELECT *
    FROM (
        SELECT *,
               ROW_NUMBER() OVER(
                   PARTITION BY product_id
                   ORDER BY effective_date DESC
               ) rn
        FROM price_history
    ) t
    WHERE rn = 1
) ph
ON cr.product_id = ph.product_id

LEFT JOIN IDENTIFIER(COALESCE(NULLIF(:catalog, ''), 'dev')||'.silver.products_scd2') p
ON cr.product_id = p.product_id
AND p.is_current = TRUE

LEFT JOIN supplier_metrics sm
ON p.supplier_id = sm.supplier_id

LEFT JOIN  IDENTIFIER(COALESCE(NULLIF(:catalog, ''), 'dev')||'.silver.suppliers_clean') sp
ON sm.supplier_id = sp.supplier_id;
