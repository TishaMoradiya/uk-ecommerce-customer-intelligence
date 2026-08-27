-- ============================================================
-- UK E-Commerce Customer Intelligence
-- Business Analysis
-- ============================================================
-- Dataset: Online Retail II
-- Period: December 2009 - December 2011
-- Clean sales records: 1,007,913
-- ============================================================

USE uk_ecommerce_intelligence;

-- ============================================================
-- 1. EXECUTIVE KPI SUMMARY
-- ============================================================

SELECT
    ROUND(SUM(Revenue), 2) AS total_revenue,
    COUNT(DISTINCT Invoice) AS total_orders,
    SUM(Quantity) AS units_sold,
    COUNT(DISTINCT CustomerID) AS unique_customers,
    ROUND(
        SUM(Revenue) / COUNT(DISTINCT Invoice),
        2
    ) AS average_order_value
FROM clean_sales;

-- ============================================================
-- 2. MONTHLY SALES PERFORMANCE
-- ============================================================

SELECT
    DATE_FORMAT(InvoiceDate, '%Y-%m') AS sales_month,
    COUNT(DISTINCT Invoice) AS total_orders,
    SUM(Quantity) AS units_sold,
    ROUND(SUM(Revenue), 2) AS monthly_revenue
FROM clean_sales
GROUP BY DATE_FORMAT(InvoiceDate, '%Y-%m')
ORDER BY sales_month;

-- Month-over-month revenue growth
WITH monthly_sales AS (
    SELECT
        DATE_FORMAT(InvoiceDate, '%Y-%m') AS sales_month,
        ROUND(SUM(Revenue), 2) AS monthly_revenue
    FROM clean_sales
    GROUP BY DATE_FORMAT(InvoiceDate, '%Y-%m')
)

SELECT
    sales_month,
    monthly_revenue,
    LAG(monthly_revenue) OVER (
        ORDER BY sales_month
    ) AS previous_month_revenue,
    ROUND(
        (
            monthly_revenue
            - LAG(monthly_revenue) OVER (ORDER BY sales_month)
        )
        / LAG(monthly_revenue) OVER (ORDER BY sales_month)
        * 100,
        2
    ) AS mom_growth_pct
FROM monthly_sales
ORDER BY sales_month;

-- ============================================================
-- 3. GEOGRAPHIC PERFORMANCE
-- ============================================================

SELECT
    Country,
    COUNT(DISTINCT Invoice) AS total_orders,
    COUNT(DISTINCT CustomerID) AS unique_customers,
    SUM(Quantity) AS units_sold,
    ROUND(SUM(Revenue), 2) AS total_revenue,
    ROUND(
        SUM(Revenue) / COUNT(DISTINCT Invoice),
        2
    ) AS average_order_value,
    ROUND(
        SUM(Revenue) * 100.0 /
        SUM(SUM(Revenue)) OVER (),
        2
    ) AS revenue_share_pct
FROM clean_sales
GROUP BY Country
ORDER BY total_revenue DESC;

-- ============================================================
-- 4. PRODUCT PERFORMANCE
-- ============================================================

SELECT
    StockCode,
    Description,
    SUM(Quantity) AS units_sold,
    COUNT(DISTINCT Invoice) AS orders_containing_product,
    ROUND(SUM(Revenue), 2) AS product_revenue,
    ROUND(AVG(Price), 2) AS average_unit_price,
    ROUND(
        SUM(Revenue) * 100.0 /
        SUM(SUM(Revenue)) OVER (),
        2
    ) AS revenue_share_pct
FROM clean_sales
GROUP BY StockCode, Description
ORDER BY product_revenue DESC
LIMIT 20;


-- Product ranking excluding service / non-merchandise lines
SELECT
    StockCode,
    Description,
    SUM(Quantity) AS units_sold,
    COUNT(DISTINCT Invoice) AS orders_containing_product,
    ROUND(SUM(Revenue), 2) AS product_revenue
FROM clean_sales
WHERE UPPER(Description) NOT IN (
    'POSTAGE',
    'DOTCOM POSTAGE',
    'MANUAL'
)
GROUP BY StockCode, Description
ORDER BY product_revenue DESC
LIMIT 20;


-- ============================================================
-- 5. CUSTOMER BEHAVIOUR
-- ============================================================

SELECT
    CustomerID,
    COUNT(DISTINCT Invoice) AS total_orders,
    SUM(Quantity) AS total_units,
    ROUND(SUM(Revenue), 2) AS customer_revenue,
    ROUND(
        SUM(Revenue) / COUNT(DISTINCT Invoice),
        2
    ) AS average_order_value,
    MIN(InvoiceDate) AS first_purchase,
    MAX(InvoiceDate) AS last_purchase
FROM clean_sales
WHERE CustomerID IS NOT NULL
GROUP BY CustomerID
ORDER BY customer_revenue DESC
LIMIT 20;


-- ============================================================
-- 6. CUSTOMER REVENUE CONCENTRATION
-- ============================================================

WITH customer_revenue AS (
    SELECT
        CustomerID,
        ROUND(SUM(Revenue), 2) AS customer_revenue
    FROM clean_sales
    WHERE CustomerID IS NOT NULL
    GROUP BY CustomerID
),

ranked_customers AS (
    SELECT
        CustomerID,
        customer_revenue,
        ROW_NUMBER() OVER (
            ORDER BY customer_revenue DESC
        ) AS revenue_rank,
        COUNT(*) OVER () AS total_customers,
        SUM(customer_revenue) OVER () AS identified_customer_revenue
    FROM customer_revenue
)

SELECT
    COUNT(*) AS top_10_pct_customers,
    ROUND(SUM(customer_revenue), 2) AS top_10_pct_revenue,
    ROUND(
        SUM(customer_revenue) * 100.0 /
        MAX(identified_customer_revenue),
        2
    ) AS revenue_share_pct
FROM ranked_customers
WHERE revenue_rank <= CEIL(total_customers * 0.10);

-- ============================================================
-- 7. RFM CUSTOMER SEGMENTATION
-- ============================================================

WITH rfm_base AS (
    SELECT
        CustomerID,

        DATEDIFF(
            (SELECT MAX(InvoiceDate) FROM clean_sales),
            MAX(InvoiceDate)
        ) AS recency_days,

        COUNT(DISTINCT Invoice) AS frequency,

        ROUND(SUM(Revenue), 2) AS monetary

    FROM clean_sales
    WHERE CustomerID IS NOT NULL
    GROUP BY CustomerID
)

SELECT
    CustomerID,
    recency_days,
    frequency,
    monetary
FROM rfm_base
ORDER BY monetary DESC
LIMIT 20;

-- RFM scoring

WITH rfm_base AS (
    SELECT
        CustomerID,
        DATEDIFF(
            (SELECT MAX(InvoiceDate) FROM clean_sales),
            MAX(InvoiceDate)
        ) AS recency_days,
        COUNT(DISTINCT Invoice) AS frequency,
        ROUND(SUM(Revenue), 2) AS monetary
    FROM clean_sales
    WHERE CustomerID IS NOT NULL
    GROUP BY CustomerID
),

rfm_scores AS (
    SELECT
        CustomerID,
        recency_days,
        frequency,
        monetary,

        NTILE(5) OVER (
            ORDER BY recency_days DESC
        ) AS recency_score,

        NTILE(5) OVER (
            ORDER BY frequency ASC
        ) AS frequency_score,

        NTILE(5) OVER (
            ORDER BY monetary ASC
        ) AS monetary_score

    FROM rfm_base
)

SELECT *
FROM rfm_scores
ORDER BY monetary DESC
LIMIT 20;

-- ============================================================
-- 8. RFM CUSTOMER SEGMENTS
-- ============================================================

WITH rfm_base AS (
    SELECT
        CustomerID,
        DATEDIFF(
            (SELECT MAX(InvoiceDate) FROM clean_sales),
            MAX(InvoiceDate)
        ) AS recency_days,
        COUNT(DISTINCT Invoice) AS frequency,
        ROUND(SUM(Revenue), 2) AS monetary
    FROM clean_sales
    WHERE CustomerID IS NOT NULL
    GROUP BY CustomerID
),

rfm_scores AS (
    SELECT
        CustomerID,
        recency_days,
        frequency,
        monetary,

        NTILE(5) OVER (
            ORDER BY recency_days DESC
        ) AS recency_score,

        NTILE(5) OVER (
            ORDER BY frequency ASC
        ) AS frequency_score,

        NTILE(5) OVER (
            ORDER BY monetary ASC
        ) AS monetary_score

    FROM rfm_base
),

rfm_segments AS (
    SELECT
        *,
        CASE
            WHEN recency_score >= 4
                 AND frequency_score >= 4
                 AND monetary_score >= 4
                THEN 'Champions'

            WHEN recency_score >= 3
                 AND frequency_score >= 4
                THEN 'Loyal Customers'

            WHEN recency_score >= 4
                 AND frequency_score <= 3
                THEN 'Potential Loyalists'

            WHEN recency_score <= 2
                 AND frequency_score >= 4
                THEN 'At Risk'

            WHEN recency_score <= 2
                 AND frequency_score <= 2
                THEN 'Lost Customers'

            ELSE 'Needs Attention'
        END AS customer_segment

    FROM rfm_scores
)

SELECT
    customer_segment,
    COUNT(*) AS customers,
    ROUND(SUM(monetary), 2) AS segment_revenue,
    ROUND(AVG(monetary), 2) AS avg_customer_value
FROM rfm_segments
GROUP BY customer_segment
ORDER BY segment_revenue DESC;


-- ============================================================
-- 9. REPEAT VS ONE-TIME CUSTOMERS
-- ============================================================

WITH customer_orders AS (
    SELECT
        CustomerID,
        COUNT(DISTINCT Invoice) AS total_orders,
        ROUND(SUM(Revenue), 2) AS customer_revenue
    FROM clean_sales
    WHERE CustomerID IS NOT NULL
    GROUP BY CustomerID
)

SELECT
    CASE
        WHEN total_orders = 1 THEN 'One-Time Customer'
        ELSE 'Repeat Customer'
    END AS customer_type,

    COUNT(*) AS customers,

    ROUND(SUM(customer_revenue), 2) AS total_revenue,

    ROUND(AVG(customer_revenue), 2) AS avg_customer_value

FROM customer_orders

GROUP BY
    CASE
        WHEN total_orders = 1 THEN 'One-Time Customer'
        ELSE 'Repeat Customer'
    END

ORDER BY total_revenue DESC;


-- ============================================================
-- 10. UK VS INTERNATIONAL PERFORMANCE
-- ============================================================

SELECT
    CASE
        WHEN Country = 'United Kingdom'
            THEN 'United Kingdom'
        ELSE 'International'
    END AS market,

    COUNT(DISTINCT Invoice) AS total_orders,
    COUNT(DISTINCT CustomerID) AS unique_customers,
    SUM(Quantity) AS units_sold,
    ROUND(SUM(Revenue), 2) AS total_revenue,

    ROUND(
        SUM(Revenue) / COUNT(DISTINCT Invoice),
        2
    ) AS average_order_value,

    ROUND(
        SUM(Revenue) * 100.0 /
        SUM(SUM(Revenue)) OVER (),
        2
    ) AS revenue_share_pct

FROM clean_sales

GROUP BY
    CASE
        WHEN Country = 'United Kingdom'
            THEN 'United Kingdom'
        ELSE 'International'
    END

ORDER BY total_revenue DESC;