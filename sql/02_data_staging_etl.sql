-- ============================================================================
-- APEX RETAIL GLOBAL - ENTERPRISE DATA WAREHOUSE & REVENUE ASSURANCE
-- Script: 02_data_staging_etl.sql
-- Description: Staging tables, cleansing routines, and ETL ingestion pipeline.
-- ============================================================================

IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'stg')
BEGIN
    EXEC('CREATE SCHEMA stg;');
END;
GO

-- ============================================================================
-- 1. STAGING TABLE DEFINITIONS (LANDING RAW DATA)
-- ============================================================================

IF OBJECT_ID('stg.RawCustomers', 'U') IS NOT NULL DROP TABLE stg.RawCustomers;
CREATE TABLE stg.RawCustomers (
    CustomerID VARCHAR(50),
    CustomerName NVARCHAR(255),
    Segment VARCHAR(100),
    Country NVARCHAR(100),
    Region NVARCHAR(100),
    City NVARCHAR(100),
    CreditRating VARCHAR(50),
    AccountStatus VARCHAR(100),
    OnboardingDate VARCHAR(50),
    StagedAt DATETIME2 DEFAULT SYSDATETIME()
);

IF OBJECT_ID('stg.RawProducts', 'U') IS NOT NULL DROP TABLE stg.RawProducts;
CREATE TABLE stg.RawProducts (
    ProductID VARCHAR(50),
    ProductName NVARCHAR(255),
    Category VARCHAR(100),
    SubCategory VARCHAR(100),
    UnitCost VARCHAR(50),
    StandardPrice VARCHAR(50),
    TargetMarginPct VARCHAR(50),
    MinOrderQty VARCHAR(50),
    IsDiscontinued VARCHAR(10),
    StagedAt DATETIME2 DEFAULT SYSDATETIME()
);

IF OBJECT_ID('stg.RawStores', 'U') IS NOT NULL DROP TABLE stg.RawStores;
CREATE TABLE stg.RawStores (
    StoreID VARCHAR(50),
    StoreName NVARCHAR(255),
    Channel VARCHAR(100),
    Region VARCHAR(100),
    TerritoryCode VARCHAR(50),
    RegionalManager NVARCHAR(255),
    CapacityTier VARCHAR(100),
    EstablishedYear VARCHAR(50),
    StagedAt DATETIME2 DEFAULT SYSDATETIME()
);

IF OBJECT_ID('stg.RawOrders', 'U') IS NOT NULL DROP TABLE stg.RawOrders;
CREATE TABLE stg.RawOrders (
    OrderID VARCHAR(50),
    OrderDate VARCHAR(50),
    ShipDate VARCHAR(50),
    CustomerID VARCHAR(50),
    StoreID VARCHAR(50),
    SalesRep NVARCHAR(255),
    PaymentStatus VARCHAR(100),
    ShippingMethod VARCHAR(100),
    SlaBreachFlag VARCHAR(10),
    StagedAt DATETIME2 DEFAULT SYSDATETIME()
);

IF OBJECT_ID('stg.RawOrderItems', 'U') IS NOT NULL DROP TABLE stg.RawOrderItems;
CREATE TABLE stg.RawOrderItems (
    OrderItemID VARCHAR(50),
    OrderID VARCHAR(50),
    LineNumber VARCHAR(50),
    ProductID VARCHAR(50),
    Quantity VARCHAR(50),
    UnitCost VARCHAR(50),
    UnitPrice VARCHAR(50),
    GrossRevenue VARCHAR(50),
    DiscountPct VARCHAR(50),
    DiscountAmount VARCHAR(50),
    NetRevenue VARCHAR(50),
    TotalCost VARCHAR(50),
    GrossMargin VARCHAR(50),
    TaxAmount VARCHAR(50),
    ShippingCost VARCHAR(50),
    AuditFlag VARCHAR(100),
    StagedAt DATETIME2 DEFAULT SYSDATETIME()
);
GO

-- ============================================================================
-- 2. ETL TRANSFORMATION & LOAD PIPELINE PROCEDURES
-- ============================================================================

-- 2.1 Load DimCustomer (SCD Type 1 / Type 2 foundation)
CREATE OR ALTER PROCEDURE edw.usp_Load_DimCustomer
AS
BEGIN
    SET NOCOUNT ON;

    -- Cleansing & Merge
    MERGE edw.DimCustomer AS TARGET
    USING (
        SELECT 
            LTRIM(RTRIM(CustomerID)) AS CustomerID,
            LTRIM(RTRIM(CustomerName)) AS CustomerName,
            COALESCE(LTRIM(RTRIM(Segment)), 'SMB') AS Segment,
            COALESCE(LTRIM(RTRIM(Country)), 'United States') AS Country,
            COALESCE(LTRIM(RTRIM(Region)), 'North America') AS Region,
            COALESCE(LTRIM(RTRIM(City)), 'Unassigned') AS City,
            UPPER(COALESCE(LTRIM(RTRIM(CreditRating)), 'BBB')) AS CreditRating,
            COALESCE(LTRIM(RTRIM(AccountStatus)), 'Active') AS AccountStatus,
            TRY_CAST(OnboardingDate AS DATE) AS OnboardingDate
        FROM stg.RawCustomers
        WHERE CustomerID IS NOT NULL AND LTRIM(RTRIM(CustomerID)) <> ''
    ) AS SOURCE
    ON TARGET.CustomerID = SOURCE.CustomerID
    WHEN MATCHED AND (
        TARGET.CustomerName <> SOURCE.CustomerName OR
        TARGET.Segment <> SOURCE.Segment OR
        TARGET.CreditRating <> SOURCE.CreditRating OR
        TARGET.AccountStatus <> SOURCE.AccountStatus
    )
    THEN UPDATE SET
        TARGET.CustomerName = SOURCE.CustomerName,
        TARGET.Segment = SOURCE.Segment,
        TARGET.Country = SOURCE.Country,
        TARGET.Region = SOURCE.Region,
        TARGET.City = SOURCE.City,
        TARGET.CreditRating = SOURCE.CreditRating,
        TARGET.AccountStatus = SOURCE.AccountStatus
    WHEN NOT MATCHED BY TARGET
    THEN INSERT (
        CustomerID, CustomerName, Segment, Country, Region, City,
        CreditRating, AccountStatus, OnboardingDate, IsCurrent, EffectiveDate
    )
    VALUES (
        SOURCE.CustomerID, SOURCE.CustomerName, SOURCE.Segment, SOURCE.Country, SOURCE.Region, SOURCE.City,
        SOURCE.CreditRating, SOURCE.AccountStatus, SOURCE.OnboardingDate, 1, CAST(GETDATE() AS DATE)
    );
END;
GO

-- 2.2 Load DimProduct
CREATE OR ALTER PROCEDURE edw.usp_Load_DimProduct
AS
BEGIN
    SET NOCOUNT ON;

    MERGE edw.DimProduct AS TARGET
    USING (
        SELECT 
            LTRIM(RTRIM(ProductID)) AS ProductID,
            LTRIM(RTRIM(ProductName)) AS ProductName,
            LTRIM(RTRIM(Category)) AS Category,
            LTRIM(RTRIM(SubCategory)) AS SubCategory,
            TRY_CAST(UnitCost AS DECIMAL(18,2)) AS UnitCost,
            TRY_CAST(StandardPrice AS DECIMAL(18,2)) AS StandardPrice,
            TRY_CAST(TargetMarginPct AS DECIMAL(5,2)) AS TargetMarginPct,
            COALESCE(TRY_CAST(MinOrderQty AS INT), 1) AS MinOrderQty,
            COALESCE(UPPER(LEFT(LTRIM(RTRIM(IsDiscontinued)), 1)), 'N') AS IsDiscontinued
        FROM stg.RawProducts
        WHERE ProductID IS NOT NULL
    ) AS SOURCE
    ON TARGET.ProductID = SOURCE.ProductID
    WHEN MATCHED THEN UPDATE SET
        TARGET.ProductName = SOURCE.ProductName,
        TARGET.Category = SOURCE.Category,
        TARGET.SubCategory = SOURCE.SubCategory,
        TARGET.UnitCost = SOURCE.UnitCost,
        TARGET.StandardPrice = SOURCE.StandardPrice,
        TARGET.TargetMarginPct = SOURCE.TargetMarginPct,
        TARGET.MinOrderQty = SOURCE.MinOrderQty,
        TARGET.IsDiscontinued = SOURCE.IsDiscontinued
    WHEN NOT MATCHED THEN INSERT (
        ProductID, ProductName, Category, SubCategory, UnitCost, StandardPrice, TargetMarginPct, MinOrderQty, IsDiscontinued
    )
    VALUES (
        SOURCE.ProductID, SOURCE.ProductName, SOURCE.Category, SOURCE.SubCategory, SOURCE.UnitCost, SOURCE.StandardPrice,
        SOURCE.TargetMarginPct, SOURCE.MinOrderQty, SOURCE.IsDiscontinued
    );
END;
GO

-- 2.3 Load DimStore
CREATE OR ALTER PROCEDURE edw.usp_Load_DimStore
AS
BEGIN
    SET NOCOUNT ON;

    MERGE edw.DimStore AS TARGET
    USING (
        SELECT 
            LTRIM(RTRIM(StoreID)) AS StoreID,
            LTRIM(RTRIM(StoreName)) AS StoreName,
            LTRIM(RTRIM(Channel)) AS Channel,
            LTRIM(RTRIM(Region)) AS Region,
            LTRIM(RTRIM(TerritoryCode)) AS TerritoryCode,
            LTRIM(RTRIM(RegionalManager)) AS RegionalManager,
            LTRIM(RTRIM(CapacityTier)) AS CapacityTier,
            TRY_CAST(EstablishedYear AS INT) AS EstablishedYear
        FROM stg.RawStores
        WHERE StoreID IS NOT NULL
    ) AS SOURCE
    ON TARGET.StoreID = SOURCE.StoreID
    WHEN MATCHED THEN UPDATE SET
        TARGET.StoreName = SOURCE.StoreName,
        TARGET.Channel = SOURCE.Channel,
        TARGET.Region = SOURCE.Region,
        TARGET.TerritoryCode = SOURCE.TerritoryCode,
        TARGET.RegionalManager = SOURCE.RegionalManager,
        TARGET.CapacityTier = SOURCE.CapacityTier
    WHEN NOT MATCHED THEN INSERT (
        StoreID, StoreName, Channel, Region, TerritoryCode, RegionalManager, CapacityTier, EstablishedYear
    )
    VALUES (
        SOURCE.StoreID, SOURCE.StoreName, SOURCE.Channel, SOURCE.Region, SOURCE.TerritoryCode, SOURCE.RegionalManager,
        SOURCE.CapacityTier, SOURCE.EstablishedYear
    );
END;
GO

-- 2.4 Load FactSalesOrders
CREATE OR ALTER PROCEDURE edw.usp_Load_FactSalesOrders
AS
BEGIN
    SET NOCOUNT ON;

    -- Staging transformation, surrogate key resolution, and idempotency
    INSERT INTO edw.FactSalesOrders (
        OrderItemID, OrderID, OrderDateKey, ShipDateKey, CustomerKey, ProductKey, StoreKey,
        SalesRep, ShippingMethod, PaymentStatus, SlaBreachFlag, Quantity, UnitCost, UnitPrice,
        GrossRevenue, DiscountPct, DiscountAmount, NetRevenue, TotalCost, GrossMargin, TaxAmount,
        ShippingCost, AuditFlag
    )
    SELECT 
        i.OrderItemID,
        o.OrderID,
        CAST(CONVERT(VARCHAR(8), TRY_CAST(o.OrderDate AS DATE), 112) AS INT) AS OrderDateKey,
        CAST(CONVERT(VARCHAR(8), TRY_CAST(o.ShipDate AS DATE), 112) AS INT) AS ShipDateKey,
        c.CustomerKey,
        p.ProductKey,
        s.StoreKey,
        COALESCE(o.SalesRep, 'Unassigned Sales Rep') AS SalesRep,
        COALESCE(o.ShippingMethod, 'Standard Ground') AS ShippingMethod,
        COALESCE(o.PaymentStatus, 'Pending') AS PaymentStatus,
        COALESCE(o.SlaBreachFlag, 'N') AS SlaBreachFlag,
        TRY_CAST(i.Quantity AS INT) AS Quantity,
        TRY_CAST(i.UnitCost AS DECIMAL(18,2)) AS UnitCost,
        TRY_CAST(i.UnitPrice AS DECIMAL(18,2)) AS UnitPrice,
        TRY_CAST(i.GrossRevenue AS DECIMAL(18,2)) AS GrossRevenue,
        TRY_CAST(i.DiscountPct AS DECIMAL(5,4)) AS DiscountPct,
        TRY_CAST(i.DiscountAmount AS DECIMAL(18,2)) AS DiscountAmount,
        TRY_CAST(i.NetRevenue AS DECIMAL(18,2)) AS NetRevenue,
        TRY_CAST(i.TotalCost AS DECIMAL(18,2)) AS TotalCost,
        TRY_CAST(i.GrossMargin AS DECIMAL(18,2)) AS GrossMargin,
        TRY_CAST(i.TaxAmount AS DECIMAL(18,2)) AS TaxAmount,
        TRY_CAST(i.ShippingCost AS DECIMAL(18,2)) AS ShippingCost,
        COALESCE(i.AuditFlag, 'None') AS AuditFlag
    FROM stg.RawOrderItems i
    INNER JOIN stg.RawOrders o ON i.OrderID = o.OrderID
    INNER JOIN edw.DimCustomer c ON o.CustomerID = c.CustomerID
    INNER JOIN edw.DimProduct p ON i.ProductID = p.ProductID
    INNER JOIN edw.DimStore s ON o.StoreID = s.StoreID
    WHERE NOT EXISTS (
        SELECT 1 FROM edw.FactSalesOrders existing WHERE existing.OrderItemID = i.OrderItemID
    );
END;
GO
