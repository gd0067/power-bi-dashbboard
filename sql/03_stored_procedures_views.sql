-- ============================================================================
-- APEX RETAIL GLOBAL - ENTERPRISE DATA WAREHOUSE & REVENUE ASSURANCE
-- Script: 03_stored_procedures_views.sql
-- Description: Analytical Views & Revenue Assurance Automated Audit Engine.
-- ============================================================================

-- ============================================================================
-- 1. ANALYTICAL EXECUTIVE VIEWS
-- ============================================================================

-- 1.1 Executive Monthly Commercial Performance View
CREATE OR ALTER VIEW edw.vw_ExecutiveSalesPerformance
AS
SELECT 
    d.Year,
    d.Quarter,
    d.YearQuarter,
    d.YearMonth,
    d.MonthName,
    s.Region,
    s.Channel,
    p.Category,
    p.SubCategory,
    COUNT(DISTINCT f.OrderID) AS TotalOrders,
    COUNT(f.OrderItemID) AS TotalOrderLines,
    SUM(f.Quantity) AS TotalUnitsSold,
    SUM(f.GrossRevenue) AS TotalGrossRevenue,
    SUM(f.DiscountAmount) AS TotalDiscountAmount,
    SUM(f.NetRevenue) AS TotalNetRevenue,
    SUM(f.TotalCost) AS TotalCost,
    SUM(f.GrossMargin) AS TotalGrossMargin,
    CASE 
        WHEN SUM(f.NetRevenue) = 0 THEN 0.00
        ELSE ROUND((SUM(f.GrossMargin) / SUM(f.NetRevenue)) * 100, 2)
    END AS GrossMarginPct,
    CASE 
        WHEN SUM(f.GrossRevenue) = 0 THEN 0.00
        ELSE ROUND((SUM(f.DiscountAmount) / SUM(f.GrossRevenue)) * 100, 2)
    END AS OverallDiscountRatePct
FROM edw.FactSalesOrders f
INNER JOIN edw.DimDate d ON f.OrderDateKey = d.DateKey
INNER JOIN edw.DimStore s ON f.StoreKey = s.StoreKey
INNER JOIN edw.DimProduct p ON f.ProductKey = p.ProductKey
GROUP BY 
    d.Year, d.Quarter, d.YearQuarter, d.YearMonth, d.MonthName,
    s.Region, s.Channel, p.Category, p.SubCategory;
GO

-- 1.2 Revenue Assurance Anomaly Summary View
CREATE OR ALTER VIEW edw.vw_AssuranceAnomalySummary
AS
SELECT 
    f.OrderID,
    f.OrderItemID,
    d.FullDate AS OrderDate,
    c.CustomerID,
    c.CustomerName,
    c.Segment,
    c.CreditRating,
    p.ProductName,
    p.Category,
    s.StoreName,
    s.Region,
    f.SalesRep,
    f.Quantity,
    f.UnitPrice,
    f.UnitCost,
    f.DiscountPct,
    f.DiscountAmount,
    f.NetRevenue,
    f.GrossMargin,
    f.AuditFlag,
    f.PaymentStatus,
    f.SlaBreachFlag,
    CASE 
        WHEN f.GrossMargin < 0 THEN 'Critical: Negative Gross Margin'
        WHEN f.DiscountPct >= 0.25 THEN 'High: Unauthorized Discount Leakage'
        WHEN f.SlaBreachFlag = 'Y' THEN 'Medium: SLA Delivery Violation'
        WHEN f.PaymentStatus = 'Disputed Settlement' THEN 'High: Unsettled Receivable'
        ELSE 'Normal'
    END AS RiskClassification,
    CASE 
        WHEN f.GrossMargin < 0 THEN ABS(f.GrossMargin)
        WHEN f.DiscountPct >= 0.25 THEN f.DiscountAmount
        WHEN f.PaymentStatus = 'Disputed Settlement' THEN f.NetRevenue
        ELSE 0.00
    END AS EstimatedFinancialLeakage
FROM edw.FactSalesOrders f
INNER JOIN edw.DimDate d ON f.OrderDateKey = d.DateKey
INNER JOIN edw.DimCustomer c ON f.CustomerKey = c.CustomerKey
INNER JOIN edw.DimProduct p ON f.ProductKey = p.ProductKey
INNER JOIN edw.DimStore s ON f.StoreKey = s.StoreKey
WHERE f.AuditFlag <> 'None' 
   OR f.GrossMargin < 0 
   OR f.DiscountPct >= 0.25 
   OR f.SlaBreachFlag = 'Y' 
   OR f.PaymentStatus = 'Disputed Settlement';
GO

-- 1.3 Customer Risk & Commercial Health Profile View
CREATE OR ALTER VIEW edw.vw_CustomerAssuranceProfile
AS
SELECT 
    c.CustomerID,
    c.CustomerName,
    c.Segment,
    c.Country,
    c.CreditRating,
    c.AccountStatus,
    COUNT(DISTINCT f.OrderID) AS LifetimeOrders,
    SUM(f.NetRevenue) AS TotalSpend,
    SUM(f.GrossMargin) AS TotalMarginContributed,
    SUM(CASE WHEN f.GrossMargin < 0 THEN 1 ELSE 0 END) AS NegativeMarginTransactions,
    SUM(CASE WHEN f.DiscountPct >= 0.20 THEN f.DiscountAmount ELSE 0 END) AS HighDiscountErosionAmount,
    SUM(CASE WHEN f.PaymentStatus = 'Disputed Settlement' THEN f.NetRevenue ELSE 0 END) AS DisputedReceivablesAmount,
    CASE 
        WHEN c.CreditRating IN ('BBB', 'BB') AND SUM(CASE WHEN f.PaymentStatus = 'Disputed Settlement' THEN 1 ELSE 0 END) > 0 THEN 'High Credit Risk'
        WHEN SUM(CASE WHEN f.GrossMargin < 0 THEN 1 ELSE 0 END) >= 2 THEN 'Margin Erosion Watchlist'
        ELSE 'Low Risk'
    END AS AssuranceGovernanceTier
FROM edw.DimCustomer c
INNER JOIN edw.FactSalesOrders f ON c.CustomerKey = f.CustomerKey
GROUP BY 
    c.CustomerID, c.CustomerName, c.Segment, c.Country, c.CreditRating, c.AccountStatus;
GO

-- ============================================================================
-- 2. AUTOMATED REVENUE ASSURANCE AUDIT ENGINE
-- ============================================================================

CREATE OR ALTER PROCEDURE edw.sp_RunRevenueAssuranceAudit
    @AuditStartDate DATE = NULL,
    @AuditEndDate DATE = NULL,
    @DiscountLeakageThreshold DECIMAL(5,4) = 0.2000
AS
BEGIN
    SET NOCOUNT ON;

    IF @AuditStartDate IS NULL SET @AuditStartDate = DATEADD(DAY, -30, CAST(GETDATE() AS DATE));
    IF @AuditEndDate IS NULL SET @AuditEndDate = CAST(GETDATE() AS DATE);

    DECLARE @StartDateKey INT = CAST(CONVERT(VARCHAR(8), @AuditStartDate, 112) AS INT);
    DECLARE @EndDateKey INT = CAST(CONVERT(VARCHAR(8), @AuditEndDate, 112) AS INT);

    PRINT 'Executing Revenue Assurance Automated Audit from ' + CAST(@AuditStartDate AS VARCHAR(10)) + ' to ' + CAST(@AuditEndDate AS VARCHAR(10));

    -- Temp staging for detected audit discrepancies
    IF OBJECT_ID('tempdb..#AuditDetections') IS NOT NULL DROP TABLE #AuditDetections;
    CREATE TABLE #AuditDetections (
        OrderID VARCHAR(30),
        OrderItemID VARCHAR(30),
        AuditDateKey INT,
        AuditCategory VARCHAR(50),
        AuditSeverity VARCHAR(20),
        AuditDescription NVARCHAR(255),
        FinancialExposure DECIMAL(18,2)
    );

    -- Check 1: Negative Gross Margin Breaches
    INSERT INTO #AuditDetections
    SELECT 
        f.OrderID,
        f.OrderItemID,
        f.OrderDateKey,
        'Commercial Pricing Risk',
        'Critical',
        'Negative Gross Margin: Unit selling price (' + CAST(f.UnitPrice AS VARCHAR(15)) + 
        ') fell below base cost (' + CAST(f.UnitCost AS VARCHAR(15)) + ')',
        ABS(f.GrossMargin)
    FROM edw.FactSalesOrders f
    WHERE f.OrderDateKey BETWEEN @StartDateKey AND @EndDateKey
      AND f.GrossMargin < 0;

    -- Check 2: Rogue / Unauthorized Discount Leakage
    INSERT INTO #AuditDetections
    SELECT 
        f.OrderID,
        f.OrderItemID,
        f.OrderDateKey,
        'Commercial Pricing Risk',
        'High',
        'Discount Leakage: Applied discount (' + CAST(ROUND(f.DiscountPct * 100, 1) AS VARCHAR(10)) + 
        '%) exceeds standard commercial governance policy of ' + CAST(ROUND(@DiscountLeakageThreshold * 100, 1) AS VARCHAR(10)) + '%',
        f.DiscountAmount
    FROM edw.FactSalesOrders f
    WHERE f.OrderDateKey BETWEEN @StartDateKey AND @EndDateKey
      AND f.DiscountPct >= @DiscountLeakageThreshold
      AND f.GrossMargin >= 0;

    -- Check 3: SLA Delivery Breaches on Priority Air Shipping
    INSERT INTO #AuditDetections
    SELECT 
        f.OrderID,
        f.OrderItemID,
        f.OrderDateKey,
        'Operational SLA Risk',
        'Medium',
        'SLA Delivery Breach: Express delivery exceeded committed service window on ' + f.ShippingMethod,
        f.ShippingCost * 1.50
    FROM edw.FactSalesOrders f
    WHERE f.OrderDateKey BETWEEN @StartDateKey AND @EndDateKey
      AND f.SlaBreachFlag = 'Y';

    -- Check 4: Disputed Uncollected Receivables on Low Credit Clients
    INSERT INTO #AuditDetections
    SELECT 
        f.OrderID,
        f.OrderItemID,
        f.OrderDateKey,
        'Credit & Settlement Risk',
        'High',
        'Disputed Settlement: Open unpaid receivable on customer with Credit Rating ' + c.CreditRating,
        f.NetRevenue
    FROM edw.FactSalesOrders f
    INNER JOIN edw.DimCustomer c ON f.CustomerKey = c.CustomerKey
    WHERE f.OrderDateKey BETWEEN @StartDateKey AND @EndDateKey
      AND f.PaymentStatus = 'Disputed Settlement'
      AND c.CreditRating IN ('BBB', 'BB');

    -- Insert newly identified anomalies into FactAssuranceAuditLogs
    INSERT INTO edw.FactAssuranceAuditLogs (
        AuditLogID, OrderID, OrderItemID, AuditDateKey, AuditCategory, AuditSeverity,
        AuditDescription, FinancialExposure, ResolutionStatus, Investigator
    )
    SELECT 
        'AUD-RUN-' + CAST(NEWID() AS VARCHAR(8)),
        d.OrderID,
        d.OrderItemID,
        d.AuditDateKey,
        d.AuditCategory,
        d.AuditSeverity,
        d.AuditDescription,
        d.FinancialExposure,
        'Under Executive Review',
        'Automated Assurance Audit Engine v2.4'
    FROM #AuditDetections d
    WHERE NOT EXISTS (
        SELECT 1 FROM edw.FactAssuranceAuditLogs existing
        WHERE existing.OrderItemID = d.OrderItemID
          AND existing.AuditDescription = d.AuditDescription
    );

    DECLARE @InsertedCount INT = @@ROWCOUNT;
    PRINT 'Audit run complete. Identified and logged ' + CAST(@InsertedCount AS VARCHAR(10)) + ' discrepancies.';
END;
GO
