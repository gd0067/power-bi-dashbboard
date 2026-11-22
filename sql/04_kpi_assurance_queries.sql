-- ============================================================================
-- APEX RETAIL GLOBAL - ENTERPRISE DATA WAREHOUSE & REVENUE ASSURANCE
-- Script: 04_kpi_assurance_queries.sql
-- Description: Core business intelligence, time-intelligence, and assurance audit queries.
-- ============================================================================

-- ============================================================================
-- QUERY 1: EXECUTIVE YEAR-OVER-YEAR (YoY) REVENUE & MARGIN GROWTH
-- Evaluates commercial growth trajectory across Fiscal Quarters with percentage variance.
-- ============================================================================
WITH QuarterlyMetrics AS (
    SELECT 
        d.Year,
        d.Quarter,
        d.YearQuarter,
        SUM(f.NetRevenue) AS CurrentRevenue,
        SUM(f.GrossMargin) AS CurrentGrossMargin,
        COUNT(DISTINCT f.OrderID) AS OrderCount
    FROM edw.FactSalesOrders f
    INNER JOIN edw.DimDate d ON f.OrderDateKey = d.DateKey
    GROUP BY d.Year, d.Quarter, d.YearQuarter
),
YoYCalculations AS (
    SELECT 
        q.Year,
        q.Quarter,
        q.YearQuarter,
        q.CurrentRevenue,
        LAG(q.CurrentRevenue, 4) OVER (ORDER BY q.Year, q.Quarter) AS PriorYearRevenue,
        q.CurrentGrossMargin,
        LAG(q.CurrentGrossMargin, 4) OVER (ORDER BY q.Year, q.Quarter) AS PriorYearGrossMargin,
        q.OrderCount
    FROM QuarterlyMetrics q
)
SELECT 
    YearQuarter,
    CurrentRevenue,
    PriorYearRevenue,
    CurrentRevenue - PriorYearRevenue AS RevenueYoY_DollarGrowth,
    CASE 
        WHEN PriorYearRevenue IS NULL OR PriorYearRevenue = 0 THEN NULL
        ELSE ROUND(((CurrentRevenue - PriorYearRevenue) / PriorYearRevenue) * 100, 2)
    END AS RevenueYoY_GrowthPct,
    CurrentGrossMargin,
    PriorYearGrossMargin,
    CASE 
        WHEN PriorYearGrossMargin IS NULL OR PriorYearGrossMargin = 0 THEN NULL
        ELSE ROUND(((CurrentGrossMargin - PriorYearGrossMargin) / PriorYearGrossMargin) * 100, 2)
    END AS MarginYoY_GrowthPct
FROM YoYCalculations
ORDER BY YearQuarter;


-- ============================================================================
-- QUERY 2: 3-MONTH ROLLING AVERAGE REVENUE & MOMENTUM
-- Smooths monthly revenue volatility to identify underlying sales velocity.
-- ============================================================================
WITH MonthlyAggregates AS (
    SELECT 
        d.YearMonth,
        MIN(d.FullDate) AS MonthStartDate,
        SUM(f.NetRevenue) AS MonthlyRevenue,
        SUM(f.GrossMargin) AS MonthlyGrossMargin
    FROM edw.FactSalesOrders f
    INNER JOIN edw.DimDate d ON f.OrderDateKey = d.DateKey
    GROUP BY d.YearMonth
)
SELECT 
    YearMonth,
    MonthlyRevenue,
    ROUND(AVG(MonthlyRevenue) OVER (
        ORDER BY MonthStartDate 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS Rolling3Month_AvgRevenue,
    MonthlyGrossMargin,
    ROUND(AVG(MonthlyGrossMargin) OVER (
        ORDER BY MonthStartDate 
        ROWS BETWEEN 2 PRECEDING AND CURRENT ROW
    ), 2) AS Rolling3Month_AvgGrossMargin
FROM MonthlyAggregates
ORDER BY MonthStartDate;


-- ============================================================================
-- QUERY 3: TOP 10 ACCOUNTS DRIVING DISCOUNT LEAKAGE & MARGIN EROSION
-- Identifies high-risk customer accounts where rogue discounts exceeded guidelines.
-- ============================================================================
SELECT TOP 10
    c.CustomerID,
    c.CustomerName,
    c.Segment,
    c.Country,
    c.CreditRating,
    COUNT(f.OrderItemID) AS LineItemCount,
    SUM(f.NetRevenue) AS TotalRevenue,
    SUM(f.DiscountAmount) AS TotalDiscountsGiven,
    ROUND((SUM(f.DiscountAmount) / NULLIF(SUM(f.GrossRevenue), 0)) * 100, 2) AS EffectiveDiscountRatePct,
    SUM(CASE WHEN f.GrossMargin < 0 THEN ABS(f.GrossMargin) ELSE 0 END) AS NegativeMarginErosionLoss,
    SUM(CASE WHEN f.DiscountPct >= 0.25 THEN f.DiscountAmount ELSE 0 END) AS UnauthorizedDiscountLeakageAmount
FROM edw.FactSalesOrders f
INNER JOIN edw.DimCustomer c ON f.CustomerKey = c.CustomerKey
GROUP BY 
    c.CustomerID, c.CustomerName, c.Segment, c.Country, c.CreditRating
ORDER BY UnauthorizedDiscountLeakageAmount DESC;


-- ============================================================================
-- QUERY 4: SALES REPRESENTATIVE COMMERCIAL AUDIT MATRIX
-- Compares individual sales performance, discount frequency, and margin breach rate.
-- ============================================================================
SELECT 
    f.SalesRep,
    COUNT(DISTINCT f.OrderID) AS ClosedOrders,
    SUM(f.NetRevenue) AS GeneratedRevenue,
    SUM(f.GrossMargin) AS GeneratedMargin,
    ROUND((SUM(f.GrossMargin) / NULLIF(SUM(f.NetRevenue), 0)) * 100, 2) AS RealizedMarginPct,
    ROUND(AVG(f.DiscountPct) * 100, 2) AS AverageDiscountPct,
    SUM(CASE WHEN f.DiscountPct >= 0.25 THEN 1 ELSE 0 END) AS RogueDiscountBreachCount,
    SUM(CASE WHEN f.GrossMargin < 0 THEN 1 ELSE 0 END) AS NegativeMarginOrderCount,
    DENSE_RANK() OVER (ORDER BY SUM(f.NetRevenue) DESC) AS RevenueRank,
    DENSE_RANK() OVER (ORDER BY SUM(CASE WHEN f.DiscountPct >= 0.25 THEN 1 ELSE 0 END) DESC) AS ComplianceRiskRank
FROM edw.FactSalesOrders f
GROUP BY f.SalesRep
ORDER BY GeneratedRevenue DESC;


-- ============================================================================
-- QUERY 5: REGIONAL SLA FULFILLMENT & SHIPPING BREACH COST ANALYSIS
-- Quantifies logistics operational delivery assurance breaches across territories.
-- ============================================================================
SELECT 
    s.Region,
    s.TerritoryCode,
    s.Channel,
    COUNT(f.OrderItemID) AS ShippedLineItems,
    SUM(CASE WHEN f.SlaBreachFlag = 'Y' THEN 1 ELSE 0 END) AS SlaBreachCount,
    ROUND(
        (CAST(SUM(CASE WHEN f.SlaBreachFlag = 'Y' THEN 1 ELSE 0 END) AS FLOAT) / 
         NULLIF(COUNT(f.OrderItemID), 0)) * 100, 
    2) AS SlaBreachRatePct,
    SUM(CASE WHEN f.SlaBreachFlag = 'Y' THEN f.ShippingCost * 1.5 ELSE 0 END) AS EstimatedPenaltyExposureAmount
FROM edw.FactSalesOrders f
INNER JOIN edw.DimStore s ON f.StoreKey = s.StoreKey
GROUP BY s.Region, s.TerritoryCode, s.Channel
ORDER BY SlaBreachRatePct DESC;
GO
