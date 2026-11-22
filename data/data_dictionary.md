# Enterprise Data Dictionary | Apex Retail Global
**Warehouse Schema:** `edw` (Star Schema) & `stg` (Staging Layer)  
**Date Range:** 2023-01-01 to 2024-12-31  
**Currency:** USD ($)

---

## 1. Table Inventory

| Table Name | Schema Type | Granularity | Primary Key | Description |
| :--- | :--- | :--- | :--- | :--- |
| `fact_sales_orders` | Fact Table | Order Line Item | `OrderItemID` | Transactional sales orders including quantities, prices, discounts, and margins. |
| `fact_assurance_audit_logs` | Fact Table | Audit Incident | `AuditLogID` | Exception log capturing pricing anomalies, discount breaches, and SLA penalties. |
| `raw_targets_2023_2024` | Fact Table | Month / Store / Category | Composite (`TargetMonth`, `StoreID`, `Category`) | Monthly commercial revenue and gross margin targets for 2023–2024. |
| `dim_customer` | Dimension | Customer Entity | `CustomerID` | Corporate accounts and consumers with segment and credit rating profiles. |
| `dim_product` | Dimension | Stock Keeping Unit (SKU) | `ProductID` | Merchandise hierarchy spanning Categories, Subcategories, costs, and standard prices. |
| `dim_store` | Dimension | Retail / Logistics Hub | `StoreID` | Distribution centers and retail hubs categorized by channel and territory. |
| `dim_date` | Dimension | Calendar Day | `DateKey` (YYYYMMDD) | Role-playing date dimension supporting Fiscal and Calendar time intelligence. |

---

## 2. Table Column Specifications

### 2.1 `fact_sales_orders`
| Column | Type | Nullable | Description | Sample Value |
| :--- | :--- | :--- | :--- | :--- |
| `OrderItemID` | VARCHAR(30) | No | Primary Key for order line item | `ITEM-500001` |
| `OrderID` | VARCHAR(30) | No | Parent Order Identifier | `ORD-10001` |
| `DateKey` | INT | No | Foreign key to `dim_date` (YYYYMMDD) | `20240415` |
| `OrderDate` | DATE | No | Transaction placement date | `2024-04-15` |
| `ShipDate` | DATE | No | Fulfillment shipping date | `2024-04-18` |
| `CustomerID` | VARCHAR(20) | No | Foreign key to `dim_customer` | `CUST-00042` |
| `StoreID` | VARCHAR(20) | No | Foreign key to `dim_store` | `STR-NA-01` |
| `ProductID` | VARCHAR(20) | No | Foreign key to `dim_product` | `PROD-0006` |
| `SalesRep` | NVARCHAR(100) | No | Account executive responsible | `Harvey Specter` |
| `ShippingMethod` | VARCHAR(50) | No | Logistics carrier service tier | `Express Air SLA-24` |
| `PaymentStatus` | VARCHAR(50) | No | Settlement state | `Paid in Full`, `Disputed Settlement` |
| `SlaBreachFlag` | CHAR(1) | No | Logistics SLA breach indicator (`Y` / `N`) | `N` |
| `Quantity` | INT | No | Quantity units ordered | `8` |
| `UnitCost` | DECIMAL(18,2) | No | Cost of goods per unit ($) | `720.00` |
| `UnitPrice` | DECIMAL(18,2) | No | Selling price per unit ($) | `1250.00` |
| `GrossRevenue` | DECIMAL(18,2) | No | `Quantity * UnitPrice` ($) | `10000.00` |
| `DiscountPct` | DECIMAL(5,4) | No | Discount percentage granted (0.0000 - 0.5000) | `0.1000` |
| `DiscountAmount`| DECIMAL(18,2) | No | `GrossRevenue * DiscountPct` ($) | `1000.00` |
| `NetRevenue` | DECIMAL(18,2) | No | `GrossRevenue - DiscountAmount` ($) | `9000.00` |
| `TotalCost` | DECIMAL(18,2) | No | `Quantity * UnitCost` ($) | `5760.00` |
| `GrossMargin` | DECIMAL(18,2) | No | `NetRevenue - TotalCost` ($) | `3240.00` |
| `TaxAmount` | DECIMAL(18,2) | No | Value-added or sales tax ($) | `675.00` |
| `ShippingCost` | DECIMAL(18,2) | No | Carrier shipping charge ($) | `26.90` |
| `AuditFlag` | VARCHAR(50) | No | Automated assurance finding flag | `None`, `Negative Margin Anomaly` |

---

### 2.2 `dim_customer`
| Column | Type | Nullable | Description | Sample Value |
| :--- | :--- | :--- | :--- | :--- |
| `CustomerID` | VARCHAR(20) | No | Primary Key | `CUST-00012` |
| `CustomerName` | NVARCHAR(100)| No | Client organization or individual name | `Vanguard Logistics Solutions` |
| `Segment` | VARCHAR(50) | No | Enterprise, Mid-Market, SMB, Consumer | `Enterprise` |
| `Country` | NVARCHAR(50) | No | Registered operating country | `United States` |
| `Region` | NVARCHAR(50) | No | Continental theater | `North America` |
| `City` | NVARCHAR(50) | No | Commercial headquarters city | `New York` |
| `CreditRating` | VARCHAR(10) | No | Standardized credit grade (AAA to BB) | `AA` |
| `AccountStatus`| VARCHAR(30) | No | Operational status (`Active`, `Under Audit Review`)| `Active` |
| `OnboardingDate`| DATE | Yes | Client relationship establishment date | `2021-08-14` |

---

### 2.3 `dim_product`
| Column | Type | Nullable | Description | Sample Value |
| :--- | :--- | :--- | :--- | :--- |
| `ProductID` | VARCHAR(20) | No | Primary Key | `PROD-0001` |
| `ProductName` | NVARCHAR(150)| No | Commercial SKU description | `Optima Rackmount Server X800` |
| `Category` | VARCHAR(50) | No | L1 Merchandise grouping | `Technology` |
| `SubCategory` | VARCHAR(50) | No | L2 Merchandise grouping | `Enterprise Servers` |
| `UnitCost` | DECIMAL(18,2) | No | Standard unit manufacturing/procurement cost | `1450.00` |
| `StandardPrice`| DECIMAL(18,2) | No | MSRP list price | `2400.00` |
| `TargetMarginPct`| DECIMAL(5,2)| No | Benchmark margin expectation % | `39.58` |
| `MinOrderQty` | INT | No | Minimum contract ordering quantity | `1` |
| `IsDiscontinued`| CHAR(1) | No | Lifecycle status indicator (`Y` / `N`) | `N` |

---

### 2.4 `dim_store`
| Column | Type | Nullable | Description | Sample Value |
| :--- | :--- | :--- | :--- | :--- |
| `StoreID` | VARCHAR(20) | No | Primary Key | `STR-NA-01` |
| `StoreName` | NVARCHAR(100)| No | Facility / Hub designation | `New York Metro Regional Hub` |
| `Channel` | VARCHAR(50) | No | Go-to-market channel | `Direct Enterprise` |
| `Region` | VARCHAR(50) | No | Global operating region | `North America` |
| `TerritoryCode`| VARCHAR(20) | No | Sales quota territory | `US-Northeast` |
| `RegionalManager`| NVARCHAR(100)| No| Senior director accountable | `Victoria Sterling` |
| `CapacityTier` | VARCHAR(30) | No | Logistics volume tier | `Tier 1 - Primary` |
| `EstablishedYear`| INT | No | Facility commissioning year | `2019` |
