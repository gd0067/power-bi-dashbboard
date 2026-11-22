# Power BI Desktop Report Build & Configuration Guide
**Project:** Apex Retail Global - Interactive Business Analytics & Assurance Dashboard  
**Tools Required:** Power BI Desktop (Latest Version), Microsoft Excel / SQL Server

---

## 1. Architecture & Data Ingestion Setup

### 1.1 Ingest Data via Power Query
1. Open **Power BI Desktop**.
2. Select **Get Data** > **Text/CSV** (or connect directly to your SQL Server / PostgreSQL database using the scripts in `sql/`).
3. For local flat file deployment, import the processed dimension and fact files located in `data/processed/`:
   - `fact_sales_orders.csv`
   - `dim_date.csv`
   - `dim_customer.csv`
   - `dim_product.csv`
   - `dim_store.csv`
   - `fact_assurance_audit_logs.csv`
   - `data/raw/raw_targets_2023_2024.csv`
4. Alternatively, use the advanced Power Query M transformation scripts stored in:
   - `power_bi/power_query_m/fxCalendar_generator.m`
   - `power_bi/power_query_m/fact_orders_transformation.m`
   - `power_bi/power_query_m/dim_products_transformation.m`
   - `power_bi/power_query_m/dim_customers_transformation.m`

### 1.2 Establish Star Schema Relationships
In the **Model View**, configure single-directional (1:*) relationships with referential integrity:

| From Table (Dimension 1) | Key Column | To Table (Fact *) | Foreign Key Column | Cardinality | Cross Filter Direction |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `dim_date` | `DateKey` | `fact_sales_orders` | `DateKey` | One to Many (1:*) | Single |
| `dim_customer` | `CustomerID` | `fact_sales_orders` | `CustomerID` | One to Many (1:*) | Single |
| `dim_product` | `ProductID` | `fact_sales_orders` | `ProductID` | One to Many (1:*) | Single |
| `dim_store` | `StoreID` | `fact_sales_orders` | `StoreID` | One to Many (1:*) | Single |
| `dim_date` | `Date` | `raw_targets_2023_2024` | `TargetMonth` | One to Many (1:*) | Single |
| `dim_store` | `StoreID` | `raw_targets_2023_2024` | `StoreID` | One to Many (1:*) | Single |
| `fact_sales_orders` | `OrderItemID` | `fact_assurance_audit_logs` | `OrderItemID` | One to Many (1:*) | Both / Single |

> **Crucial Setting:** Right-click on `dim_date` > select **Mark as Date Table** > choose column `Date`. This unlocks native DAX time intelligence (`TOTALYTD`, `SAMEPERIODLASTYEAR`, `DATESINPERIOD`).

---

## 2. DAX Measure Organization

Create a dedicated disconnected measure repository:
1. On the **Home** tab, click **Enter Data**, name the table `_Measures`, and click **Load**.
2. Add your custom DAX measures from `power_bi/dax_measures/`:
   - `01_core_financial_kpis.dax` (Revenue, COGS, Gross Margin, Margin %, AOV, Target Attainment)
   - `02_time_intelligence.dax` (YTD, QTD, SPLY, YoY Growth $, YoY Growth %, 3M Rolling Avg)
   - `03_assurance_and_audit.dax` (Discount Leakage, Negative Margin Count, SLA Breach Cost, Health Score)
   - `04_dynamic_formatting.dax` (Dynamic Header, Status Callouts, Color Hex Codes)
3. Hide the dummy column in `_Measures` so the table moves to the top with a calculator icon.

---

## 3. Dashboard Page Blueprint & Layout

The dashboard is structured into four specialized executive views:

```
┌────────────────────────────────────────────────────────────────────────┐
│  PAGE 1: Executive Commercial Performance & Financial Health          │
├────────────────────────────────────────────────────────────────────────┤
│  PAGE 2: Revenue Assurance, Leakage & Audit Governance                 │
├────────────────────────────────────────────────────────────────────────┤
│  PAGE 3: Customer Risk Matrix & Territory Fulfillment Performance     │
├────────────────────────────────────────────────────────────────────────┤
│  PAGE 4: Transactional Drill-Through & Line-Item Audit Deep Dive       │
└────────────────────────────────────────────────────────────────────────┘
```

### Page 1: Executive Financial Overview
- **Header Banner:**
  - Card Visual: Measure `[Dynamic Dashboard Title]`
  - Right-aligned Slicers: `dim_date[Year]`, `dim_date[Quarter]`, `dim_store[Region]`
- **Top Metric Cards (KPI Band):**
  1. **Total Net Revenue:** Value `[Total Net Revenue]`, Secondary label `[YoY Revenue Growth %]` with conditional color `[YoY Revenue Growth Color]`.
  2. **Gross Margin %:** Value `[Gross Margin %]`, Secondary label `YoY: [YoY Gross Margin Growth %]`.
  3. **Target Attainment:** Gauge / KPI Card showing `[Total Net Revenue]` vs `[Target Revenue]`.
  4. **Average Order Value (AOV):** Value `[Average Order Value]`.
  5. **Assurance Compliance Health Score:** Value `[Assurance Compliance Health Score]` / 100 with conditional color `[Assurance Health Status Color]`.
- **Center Left Visual:**
  - **Type:** Clustered Column & Line Chart
  - **X-Axis:** `dim_date[YearMonth]`
  - **Column Y-Axis:** `[Total Net Revenue]`
  - **Line Y-Axis:** `[3M Rolling Avg Revenue]`, `[Target Revenue]`
- **Center Right Visual:**
  - **Type:** Matrix / Decomposition Tree
  - **Levels:** `dim_product[Category]` > `dim_product[SubCategory]` > `dim_product[ProductName]`
  - **Values:** `[Total Net Revenue]`, `[Gross Margin %]`, `[YoY Revenue Growth %]`
- **Bottom Visuals:**
  - **Regional Performance:** Shape Map / Filled Map with `dim_store[Region]` and `[Total Net Revenue]`.
  - **Top 5 Reps Leaderboard:** Horizontal Bar Chart with `fact_sales_orders[SalesRep]` sorted by `[Total Net Revenue]`.

---

### Page 2: Revenue Assurance & Risk Audit
- **Header Alert:**
  - Card visual displaying `[Executive KPI Alert Card]` (alerts management if health drops below 85).
- **Assurance Summary Cards:**
  1. `[Discount Leakage Amount]` (Red callout)
  2. `[Negative Margin Order Count]` (Critical threshold badge)
  3. `[Negative Margin Loss]` ($ loss absorbed)
  4. `[Disputed Receivables]` ($ pending credit risk)
  5. `[SLA Breach Incidents]` (Logistics delivery failures)
- **Visual 1 (Waterfall Chart - Revenue to Realized Margin Waterfall):**
  - **Category:** Breakdown of Gross Revenue -> (- Discounts) -> (- Cost of Goods) -> (+ Shipping & Tax) -> Realized Margin.
- **Visual 2 (Scatter Plot - Commercial Risk Quadrant):**
  - **X-Axis:** `fact_sales_orders[DiscountPct]` (0% to 50%)
  - **Y-Axis:** `fact_sales_orders[GrossMargin]`
  - **Details:** `fact_sales_orders[OrderItemID]`
  - **Quadrant Highlights:** Top-Left (Healthy High Margin), Bottom-Right (Critical: Negative Margin with High Discount).
- **Visual 3 (Audit Discrepancy Table):**
  - **Columns:** `OrderID`, `OrderDate`, `CustomerName`, `ProductName`, `DiscountPct`, `GrossMargin`, `AuditFlag`, `PaymentStatus`.
  - **Conditional Formatting:** Highlight rows where `GrossMargin < 0` with Soft Red (`#FDE7E9`).

---

### Page 3: Customer & Territory Intelligence
- **Slicers:** `dim_customer[Segment]`, `dim_customer[CreditRating]`, `dim_store[Channel]`.
- **Visual 1 (Customer Risk vs Settlement Discrepancy Matrix):**
  - **Rows:** `dim_customer[Segment]`, `dim_customer[CreditRating]`
  - **Values:** `[Total Net Revenue]`, `[Disputed Receivables]`, `[High-Risk Order Ratio %]`, `[Negative Margin Order Count]`.
- **Visual 2 (Logistics SLA Breach Matrix):**
  - **X-Axis:** `dim_store[StoreName]`
  - **Y-Axis:** `[SLA Breach Rate %]`
  - **Line:** Target SLA Threshold (5.0%).

---

### Page 4: Transactional Drill-Through Deep Dive
- **Configuration:**
  - In the Visualizations pane under **Drill-through**, set **Drill-through when:** `Used as category`.
  - Add Fields: `fact_sales_orders[OrderID]`, `dim_customer[CustomerID]`, `dim_product[ProductID]`.
- **Contents:**
  - Executive summary card of selected Order / Customer.
  - Complete line-item breakdown table with unit costs, standard prices, override discounts, shipping carrier SLA metrics, and investigator notes.
  - Action button: **"← Back to Overview"** configured with Action: `Back`.

---

## 4. Color Palette & Styling Guidelines

To ensure an executive-ready look:
- **Primary Background:** `#F8F9FA` (Off-white) or `#0F172A` (Executive Slate Dark Mode)
- **Primary Brand Color:** `#1E3A8A` (Deep Navy)
- **Secondary Accent:** `#0284C7` (Corporate Cyan)
- **Success / On-Target:** `#107C41` (Emerald Green)
- **Warning / Moderate Risk:** `#D97706` (Amber)
- **Critical Breach / Loss:** `#DC2626` (Crimson)
- **Font Family:** `Segoe UI`, `Segoe UI Semibold`

---

## 5. Testing & Verification Checklist
- [x] All 1:* relationships active without ambiguity.
- [x] Date dimension marked as Official Date Table.
- [x] Time intelligence DAX measures calculate accurately without `BLANK()` errors on edge dates.
- [x] Drill-through filters pass context seamlessly between Page 1 and Page 4.
- [x] Dynamic measure formatting rules apply appropriate hex codes to KPI cards.
- [x] Slicers reset cleanly via clear-all bookmarks.
