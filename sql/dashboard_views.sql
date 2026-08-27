-- ============================================================
-- UK E-Commerce Customer Intelligence
-- Dashboard Views
-- ============================================================

USE uk_ecommerce_intelligence;
-- ============================================================
-- 1. SALES TRANSACTIONS VIEW
-- ============================================================

CREATE OR REPLACE VIEW vw_sales_transactions AS

SELECT
    Invoice,
    StockCode,
    Description,
    Quantity,
    InvoiceDate,
    DATE(InvoiceDate) AS OrderDate,
    YEAR(InvoiceDate) AS OrderYear,
    MONTH(InvoiceDate) AS OrderMonthNumber,
    DATE_FORMAT(InvoiceDate, '%Y-%m') AS YearMonth,
    Price,
    CustomerID,
    Country,
    Revenue,

    CASE
        WHEN Country = 'United Kingdom'
            THEN 'United Kingdom'
        ELSE 'International'
    END AS Market

FROM clean_sales;

-- ============================================================
-- 2. CUSTOMER RFM VIEW
-- ============================================================

CREATE OR REPLACE VIEW vw_customer_rfm AS

WITH rfm_base AS (
    SELECT
        CustomerID,

        DATEDIFF(
            (SELECT MAX(InvoiceDate) FROM clean_sales),
            MAX(InvoiceDate)
        ) AS RecencyDays,

        COUNT(DISTINCT Invoice) AS Frequency,

        ROUND(SUM(Revenue), 2) AS Monetary,

        MIN(InvoiceDate) AS FirstPurchase,

        MAX(InvoiceDate) AS LastPurchase

    FROM clean_sales

    WHERE CustomerID IS NOT NULL

    GROUP BY CustomerID
),

rfm_scores AS (
    SELECT
        CustomerID,
        RecencyDays,
        Frequency,
        Monetary,
        FirstPurchase,
        LastPurchase,

        NTILE(5) OVER (
            ORDER BY RecencyDays DESC
        ) AS RecencyScore,

        NTILE(5) OVER (
            ORDER BY Frequency ASC
        ) AS FrequencyScore,

        NTILE(5) OVER (
            ORDER BY Monetary ASC
        ) AS MonetaryScore

    FROM rfm_base
)

SELECT
    CustomerID,
    RecencyDays,
    Frequency,
    Monetary,
    FirstPurchase,
    LastPurchase,
    RecencyScore,
    FrequencyScore,
    MonetaryScore,

    CASE
        WHEN RecencyScore >= 4
             AND FrequencyScore >= 4
             AND MonetaryScore >= 4
            THEN 'Champions'

        WHEN RecencyScore >= 3
             AND FrequencyScore >= 4
            THEN 'Loyal Customers'

        WHEN RecencyScore >= 4
             AND FrequencyScore <= 3
            THEN 'Potential Loyalists'

        WHEN RecencyScore <= 2
             AND FrequencyScore >= 4
            THEN 'At Risk'

        WHEN RecencyScore <= 2
             AND FrequencyScore <= 2
            THEN 'Lost Customers'

        ELSE 'Needs Attention'

    END AS CustomerSegment,

    CASE
        WHEN Frequency = 1
            THEN 'One-Time Customer'
        ELSE 'Repeat Customer'
    END AS CustomerType

FROM rfm_scores;

-- ============================================================
-- 3. PRODUCT PERFORMANCE VIEW
-- ============================================================

CREATE OR REPLACE VIEW vw_product_performance AS

SELECT
    StockCode,
    Description,
    SUM(Quantity) AS UnitsSold,
    COUNT(DISTINCT Invoice) AS OrdersContainingProduct,
    ROUND(SUM(Revenue), 2) AS ProductRevenue,
    ROUND(AVG(Price), 2) AS AverageUnitPrice

FROM clean_sales

WHERE UPPER(Description) NOT IN (
    'POSTAGE',
    'DOTCOM POSTAGE',
    'MANUAL'
)

GROUP BY
    StockCode,
    Description;

    -- ============================================================
-- 4. GEOGRAPHIC PERFORMANCE VIEW
-- ============================================================

CREATE OR REPLACE VIEW vw_geographic_performance AS

SELECT
    Country,

    CASE
        WHEN Country = 'United Kingdom'
            THEN 'United Kingdom'
        ELSE 'International'
    END AS Market,

    COUNT(DISTINCT Invoice) AS TotalOrders,
    COUNT(DISTINCT CustomerID) AS UniqueCustomers,
    SUM(Quantity) AS UnitsSold,
    ROUND(SUM(Revenue), 2) AS TotalRevenue,

    ROUND(
        SUM(Revenue) / COUNT(DISTINCT Invoice),
        2
    ) AS AverageOrderValue

FROM clean_sales

GROUP BY Country;

