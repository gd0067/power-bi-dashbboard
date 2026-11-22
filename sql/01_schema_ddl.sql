-- ============================================================================
-- APEX RETAIL GLOBAL - ENTERPRISE DATA WAREHOUSE & REVENUE ASSURANCE
-- Script: 01_schema_ddl.sql
-- Description: DDL definitions for Star Schema architecture.
-- Author: Data Analytics & Financial Assurance Team
-- Target Platform: Microsoft SQL Server (T-SQL) / Azure SQL / Synapse Analytics
-- Compatible with: PostgreSQL / Snowflake (with standard syntax adjustments)
-- ============================================================================

-- Create Database Schema
IF NOT EXISTS (SELECT * FROM sys.schemas WHERE name = 'edw')
BEGIN
    EXEC('CREATE SCHEMA edw;');
END;
GO

-- ============================================================================
-- 1. DIMENSION TABLES
-- ============================================================================

-- 1.1 Date Dimension (Role-playing support for Order Date & Ship Date)
IF OBJECT_ID('edw.DimDate', 'U') IS NOT NULL DROP TABLE edw.DimDate;
CREATE TABLE edw.DimDate (
    DateKey INT NOT NULL,                          -- Format: YYYYMMDD
    FullDate DATE NOT NULL,
    Year INT NOT NULL,
    Quarter VARCHAR(2) NOT NULL,                  -- 'Q1', 'Q2', 'Q3', 'Q4'
    YearQuarter VARCHAR(7) NOT NULL,              -- '2024-Q1'
    MonthNum INT NOT NULL,                        -- 1 to 12
    MonthName VARCHAR(20) NOT NULL,               -- 'January'
    MonthShort VARCHAR(3) NOT NULL,               -- 'Jan'
    YearMonth VARCHAR(7) NOT NULL,                -- '2024-01'
    DayOfWeek VARCHAR(15) NOT NULL,               -- 'Monday'
    DayOfWeekNum INT NOT NULL,                    -- 1 = Sunday/Monday depending on config
    IsWeekend BIT NOT NULL,                       -- 1 = Weekend, 0 = Weekday
    FiscalYear VARCHAR(6) NOT NULL,               -- 'FY2024'
    FiscalQuarter VARCHAR(6) NOT NULL,            -- 'FY24-Q1'
    CONSTRAINT PK_DimDate PRIMARY KEY CLUSTERED (DateKey)
);
GO

-- 1.2 Customer Dimension
IF OBJECT_ID('edw.DimCustomer', 'U') IS NOT NULL DROP TABLE edw.DimCustomer;
CREATE TABLE edw.DimCustomer (
    CustomerKey INT IDENTITY(1,1) NOT NULL,       -- Surrogate Key
    CustomerID VARCHAR(20) NOT NULL,              -- Business / Natural Key
    CustomerName NVARCHAR(100) NOT NULL,
    Segment VARCHAR(50) NOT NULL,                 -- 'Enterprise', 'Mid-Market', 'SMB', 'Consumer'
    Country NVARCHAR(50) NOT NULL,
    Region NVARCHAR(50) NOT NULL,
    City NVARCHAR(50) NOT NULL,
    CreditRating VARCHAR(10) NOT NULL,            -- 'AAA', 'AA', 'A', 'BBB', 'BB'
    AccountStatus VARCHAR(30) NOT NULL,           -- 'Active', 'Under Audit Review'
    OnboardingDate DATE NULL,
    IsCurrent BIT NOT NULL DEFAULT 1,             -- SCD Type 2 indicator
    EffectiveDate DATE NOT NULL DEFAULT '2021-01-01',
    ExpiryDate DATE NULL,
    CONSTRAINT PK_DimCustomer PRIMARY KEY CLUSTERED (CustomerKey),
    CONSTRAINT UQ_DimCustomer_CustomerID UNIQUE (CustomerID)
);
GO

-- 1.3 Product Dimension
IF OBJECT_ID('edw.DimProduct', 'U') IS NOT NULL DROP TABLE edw.DimProduct;
CREATE TABLE edw.DimProduct (
    ProductKey INT IDENTITY(1,1) NOT NULL,        -- Surrogate Key
    ProductID VARCHAR(20) NOT NULL,               -- Business / Natural Key
    ProductName NVARCHAR(150) NOT NULL,
    Category VARCHAR(50) NOT NULL,                -- 'Technology', 'Office Supplies', 'Furniture', 'Industrial & Safety'
    SubCategory VARCHAR(50) NOT NULL,
    UnitCost DECIMAL(18,2) NOT NULL,
    StandardPrice DECIMAL(18,2) NOT NULL,
    TargetMarginPct DECIMAL(5,2) NOT NULL,
    MinOrderQty INT NOT NULL DEFAULT 1,
    IsDiscontinued CHAR(1) NOT NULL DEFAULT 'N',
    CONSTRAINT PK_DimProduct PRIMARY KEY CLUSTERED (ProductKey),
    CONSTRAINT UQ_DimProduct_ProductID UNIQUE (ProductID)
);
GO

-- 1.4 Store / Territory Dimension
IF OBJECT_ID('edw.DimStore', 'U') IS NOT NULL DROP TABLE edw.DimStore;
CREATE TABLE edw.DimStore (
    StoreKey INT IDENTITY(1,1) NOT NULL,          -- Surrogate Key
    StoreID VARCHAR(20) NOT NULL,                 -- Business / Natural Key
    StoreName NVARCHAR(100) NOT NULL,
    Channel VARCHAR(50) NOT NULL,                 -- 'Direct Enterprise', 'Online B2B', 'Retail Partner'
    Region VARCHAR(50) NOT NULL,
    TerritoryCode VARCHAR(20) NOT NULL,
    RegionalManager NVARCHAR(100) NOT NULL,
    CapacityTier VARCHAR(30) NOT NULL,            -- 'Tier 1 - Primary', 'Tier 2 - Satellite'
    EstablishedYear INT NOT NULL,
    CONSTRAINT PK_DimStore PRIMARY KEY CLUSTERED (StoreKey),
    CONSTRAINT UQ_DimStore_StoreID UNIQUE (StoreID)
);
GO

-- ============================================================================
-- 2. FACT TABLES
-- ============================================================================

-- 2.1 Fact Sales Orders (Transaction Grain: Order Line Item)
IF OBJECT_ID('edw.FactSalesOrders', 'U') IS NOT NULL DROP TABLE edw.FactSalesOrders;
CREATE TABLE edw.FactSalesOrders (
    SalesOrderLineKey BIGINT IDENTITY(1,1) NOT NULL,
    OrderItemID VARCHAR(30) NOT NULL,             -- Degenerate Dimension / Business Key
    OrderID VARCHAR(30) NOT NULL,
    OrderDateKey INT NOT NULL,                    -- FK to DimDate
    ShipDateKey INT NOT NULL,                     -- FK to DimDate
    CustomerKey INT NOT NULL,                     -- FK to DimCustomer
    ProductKey INT NOT NULL,                      -- FK to DimProduct
    StoreKey INT NOT NULL,                        -- FK to DimStore
    SalesRep NVARCHAR(100) NOT NULL,
    ShippingMethod VARCHAR(50) NOT NULL,
    PaymentStatus VARCHAR(50) NOT NULL,           -- 'Paid in Full', 'Net 30 Pending', 'Disputed Settlement'
    SlaBreachFlag CHAR(1) NOT NULL DEFAULT 'N',    -- 'Y' or 'N'
    Quantity INT NOT NULL,
    UnitCost DECIMAL(18,2) NOT NULL,
    UnitPrice DECIMAL(18,2) NOT NULL,
    GrossRevenue DECIMAL(18,2) NOT NULL,
    DiscountPct DECIMAL(5,4) NOT NULL,
    DiscountAmount DECIMAL(18,2) NOT NULL,
    NetRevenue DECIMAL(18,2) NOT NULL,
    TotalCost DECIMAL(18,2) NOT NULL,
    GrossMargin DECIMAL(18,2) NOT NULL,
    TaxAmount DECIMAL(18,2) NOT NULL,
    ShippingCost DECIMAL(18,2) NOT NULL,
    AuditFlag VARCHAR(50) NOT NULL DEFAULT 'None',-- 'None', 'Negative Margin Anomaly', 'Unauthorized Discount Leakage'
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),
    
    CONSTRAINT PK_FactSalesOrders PRIMARY KEY CLUSTERED (SalesOrderLineKey),
    CONSTRAINT FK_FactSalesOrders_OrderDate FOREIGN KEY (OrderDateKey) REFERENCES edw.DimDate(DateKey),
    CONSTRAINT FK_FactSalesOrders_ShipDate FOREIGN KEY (ShipDateKey) REFERENCES edw.DimDate(DateKey),
    CONSTRAINT FK_FactSalesOrders_Customer FOREIGN KEY (CustomerKey) REFERENCES edw.DimCustomer(CustomerKey),
    CONSTRAINT FK_FactSalesOrders_Product FOREIGN KEY (ProductKey) REFERENCES edw.DimProduct(ProductKey),
    CONSTRAINT FK_FactSalesOrders_Store FOREIGN KEY (StoreKey) REFERENCES edw.DimStore(StoreKey)
);
GO

-- 2.2 Fact Assurance Audit Logs (Grain: Audit Discrepancy Event)
IF OBJECT_ID('edw.FactAssuranceAuditLogs', 'U') IS NOT NULL DROP TABLE edw.FactAssuranceAuditLogs;
CREATE TABLE edw.FactAssuranceAuditLogs (
    AuditLogKey BIGINT IDENTITY(1,1) NOT NULL,
    AuditLogID VARCHAR(30) NOT NULL,
    OrderID VARCHAR(30) NOT NULL,
    OrderItemID VARCHAR(30) NULL,
    AuditDateKey INT NOT NULL,                    -- FK to DimDate
    AuditCategory VARCHAR(50) NOT NULL,           -- 'Commercial Pricing Risk', 'Operational SLA Risk', 'Credit & Settlement Risk'
    AuditSeverity VARCHAR(20) NOT NULL,           -- 'Critical', 'High', 'Medium', 'Low'
    AuditDescription NVARCHAR(255) NOT NULL,
    FinancialExposure DECIMAL(18,2) NOT NULL,     -- Risk / Leakage dollar amount
    ResolutionStatus VARCHAR(50) NOT NULL,        -- 'Under Executive Review', 'Resolved - Mitigated'
    Investigator NVARCHAR(100) NOT NULL DEFAULT 'Assurance Analytics Engine',
    LoggedAt DATETIME2 NOT NULL DEFAULT SYSDATETIME(),

    CONSTRAINT PK_FactAssuranceAuditLogs PRIMARY KEY CLUSTERED (AuditLogKey),
    CONSTRAINT FK_FactAssuranceAuditLogs_Date FOREIGN KEY (AuditDateKey) REFERENCES edw.DimDate(DateKey)
);
GO

-- 2.3 Fact Monthly Targets (Grain: Monthly Target by Store & Category)
IF OBJECT_ID('edw.FactMonthlyTargets', 'U') IS NOT NULL DROP TABLE edw.FactMonthlyTargets;
CREATE TABLE edw.FactMonthlyTargets (
    TargetKey INT IDENTITY(1,1) NOT NULL,
    TargetDateKey INT NOT NULL,                   -- First day of month (YYYYMM01)
    StoreKey INT NOT NULL,                        -- FK to DimStore
    Category VARCHAR(50) NOT NULL,
    TargetRevenue DECIMAL(18,2) NOT NULL,
    TargetMarginAmount DECIMAL(18,2) NOT NULL,
    TargetMarginPct DECIMAL(5,2) NOT NULL,

    CONSTRAINT PK_FactMonthlyTargets PRIMARY KEY CLUSTERED (TargetKey),
    CONSTRAINT FK_FactMonthlyTargets_Date FOREIGN KEY (TargetDateKey) REFERENCES edw.DimDate(DateKey),
    CONSTRAINT FK_FactMonthlyTargets_Store FOREIGN KEY (StoreKey) REFERENCES edw.DimStore(StoreKey)
);
GO

-- ============================================================================
-- 3. PERFORMANCE INDEXES
-- ============================================================================
CREATE NONCLUSTERED INDEX IX_FactSalesOrders_CustomerKey ON edw.FactSalesOrders (CustomerKey) INCLUDE (NetRevenue, GrossMargin);
CREATE NONCLUSTERED INDEX IX_FactSalesOrders_ProductKey ON edw.FactSalesOrders (ProductKey) INCLUDE (Quantity, NetRevenue);
CREATE NONCLUSTERED INDEX IX_FactSalesOrders_StoreKey ON edw.FactSalesOrders (StoreKey) INCLUDE (NetRevenue);
CREATE NONCLUSTERED INDEX IX_FactSalesOrders_OrderDateKey ON edw.FactSalesOrders (OrderDateKey) INCLUDE (NetRevenue, GrossMargin, TotalCost);
CREATE NONCLUSTERED INDEX IX_FactSalesOrders_AuditFlag ON edw.FactSalesOrders (AuditFlag) WHERE AuditFlag <> 'None';
CREATE NONCLUSTERED INDEX IX_FactAssuranceAudit_Severity ON edw.FactAssuranceAuditLogs (AuditSeverity, ResolutionStatus) INCLUDE (FinancialExposure);
GO
