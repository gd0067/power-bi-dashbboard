# Enterprise Business Analytics & Revenue Assurance Dashboard
**Technology Stack:** Power BI | Microsoft SQL Server / T-SQL | Microsoft Excel | Power Query (M)  
**Methodology:** Kimball Dimensional Modeling (Star Schema) | Revenue & Operational Assurance  

---

## Project Overview

This repository contains an end-to-end enterprise analytics solution designed to evaluate commercial performance and detect revenue leakage. Using raw transactional datasets spanning 2023 to 2024, the pipeline extracts, cleanses, and transforms data across SQL and Power Query, models it in a high-performance Star Schema, and serves it through an interactive 4-page Power BI dashboard.

### Core Capabilities Built
- **ETL & Data Modeling:** Cleaned and staged 9,400+ line-item transactions into a star schema with strict `1:*` single-direction relationships.
- **Advanced DAX Library:** Implemented Time Intelligence (YoY growth, YTD, 3-month rolling averages, cumulative totals) and custom financial audit KPIs.
- **Assurance & Governance Engine:** Automated detection of unauthorized discount leakage, negative gross margin transactions, and logistics SLA breaches.
- **Cross-Tool Financial Reconciliation:** Built a 3-way reconciliation model across ERP extracts, SQL warehouse facts, and Power BI models in Excel with $0.00 unexplained variance.

---

## Repository Structure

```
├── README.md                               # Project documentation & release notes
├── .gitignore                              # Git exclusion rules
├── data/
│   ├── raw/                                # Raw landing datasets (CSV)
│   │   ├── raw_orders_transactions.csv
│   │   ├── raw_order_items.csv
│   │   ├── raw_products_catalog.csv
│   │   ├── raw_customers.csv
│   │   ├── raw_territories_stores.csv
│   │   └── raw_targets_2023_2024.csv
│   ├── processed/                          # Processed Star Schema dimension & fact extracts
│   │   ├── fact_sales_orders.csv
│   │   ├── fact_assurance_audit_logs.csv
│   │   ├── dim_customer.csv
│   │   ├── dim_product.csv
│   │   ├── dim_store.csv
│   │   └── dim_date.csv
│   └── data_dictionary.md                  # Detailed schema definitions & data types
├── sql/
│   ├── 01_schema_ddl.sql                   # Star schema DDL with constraints and indexes
│   ├── 02_data_staging_etl.sql             # Staging tables & MERGE-based ETL procedures
│   ├── 03_stored_procedures_views.sql      # Analytical views & automated audit detection procedure
│   └── 04_kpi_assurance_queries.sql       # Complex analytical SQL queries (CTEs, Window Functions)
├── power_bi/
│   ├── pbix_guide.md                       # Comprehensive guide to build the Power BI dashboard
│   ├── data_model_star_schema.svg          # Visual Star Schema relationship diagram
│   ├── dax_measures/
│   │   ├── 01_core_financial_kpis.dax      # Commercial KPIs (Revenue, Margin, AOV, Targets)
│   │   ├── 02_time_intelligence.dax       # Time intelligence (YTD, SPLY, YoY, 3M Moving Avg)
│   │   ├── 03_assurance_and_audit.dax     # Financial audit & governance metrics
│   │   └── 04_dynamic_formatting.dax      # Dynamic titles, status alerts, hex color codes
│   └── power_query_m/
│       ├── fxCalendar_generator.m          # Dynamic date dimension generation function
│       ├── fact_orders_transformation.m    # Applied transformation steps for sales orders
│       ├── dim_products_transformation.m   # Product tiering & category mapping
│       └── dim_customers_transformation.m  # Customer cleansing & credit risk tiering
├── excel/
│   ├── financial_assurance_reconciliation.xlsx # 3-way audit reconciliation workbook
│   └── financial_reconciliation_model.md       # Reconciliation methodology & formula guide
├── docs/
│   ├── architecture.md                     # Kimball data modeling architecture document
│   ├── dax_formula_reference.md            # Comprehensive DAX calculation handbook
│   └── assurance_framework.md             # Revenue assurance audit policies & thresholds
└── scripts/
    ├── generate_synthetic_data.ps1         # Reproducible dataset generator
    └── build_excel_model.ps1               # OpenXML Excel model builder
```

---

## Data Model Architecture

The data model uses a Star Schema centered on `fact_sales_orders` (grain: transaction line item) connected via single-directional one-to-many (`1:*`) relationships to four conformed dimensions:

```
                  ┌──────────────────────┐
                  │       dim_date       │
                  └──────────┬───────────┘
                             │ (1:*)
┌──────────────────────┐     ▼     ┌──────────────────────┐
│     dim_customer     │ ──> ★ <── │     dim_product      │
└──────────────────────┘     ▲     └──────────────────────┘
                             │ (1:*)
                  ┌──────────┴───────────┐
                  │      dim_store       │
                  └──────────────────────┘
```

See [data_model_star_schema.svg](power_bi/data_model_star_schema.svg) for the full entity-relationship visual.

---

## Key SQL Capabilities

- **Automated Audit Procedure (`sp_RunRevenueAssuranceAudit`):** Evaluates transactions against business thresholds (margins < 0%, discounts >= 25%, delayed shipments, unpaid receivables) and automatically writes exception events into `FactAssuranceAuditLogs`.
- **Analytical Reporting Queries (`04_kpi_assurance_queries.sql`):** Uses window functions (`LAG`, `OVER`, `ROWS BETWEEN`) to evaluate YoY revenue/margin variance and rolling 3-month sales trajectories without self-joins.

---

## DAX Measures Highlights

- **Time Intelligence:**
  ```dax
  YoY Revenue Growth % = 
  VAR _Current = [Total Net Revenue]
  VAR _Prior = [Revenue SPLY]
  RETURN
      DIVIDE ( _Current - _Prior, _Prior, BLANK () )
  ```
- **Assurance Anomaly Quantification:**
  ```dax
  Discount Leakage Amount = 
  CALCULATE ( 
      SUM ( fact_sales_orders[DiscountAmount] ), 
      fact_sales_orders[DiscountPct] >= 0.25 
  )
  ```
- **Composite Compliance Index:**
  ```dax
  Assurance Compliance Health Score = 
  VAR _LeakagePenalty = [Discount Leakage Ratio %] * 150
  VAR _MarginPenalty = DIVIDE ( [Negative Margin Order Count], [Total Line Items], 0 ) * 200
  VAR _SlaPenalty = [SLA Breach Rate %] * 100
  RETURN
      MAX ( 0, MIN ( 100, ROUND ( 100 - ( _LeakagePenalty + _MarginPenalty + _SlaPenalty ), 1 ) ) )
  ```

---

## Power BI Dashboard Blueprint

The report is structured into four functional pages:
1. **Executive Performance & Assurance Overview:** Dynamic headline KPIs, monthly revenue vs. 3M moving average, target variance gauge, regional breakdown.
2. **Revenue Assurance & Governance Audit:** Waterfall margin analysis, discount vs. margin scatter plot, audit discrepancy exception table with conditional row highlights.
3. **Customer Risk & Territory Fulfillment:** Segment credit tier analysis, unpaid receivables tracking, logistics SLA delivery breach rates.
4. **Transactional Drill-Through:** Order line-item inspection with pricing history, delivery SLAs, and investigator notes.

Full visual layout instructions and formatting properties are documented in [power_bi/pbix_guide.md](power_bi/pbix_guide.md).

---

## Getting Started

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/business-analytics-assurance-dashboard.git
   cd business-analytics-assurance-dashboard
   ```
2. **Database Setup (Optional):**
   - Execute `sql/01_schema_ddl.sql` in SQL Server Management Studio or Azure Data Studio.
   - Run `sql/02_data_staging_etl.sql` to load staged CSV files and populate the star schema.
3. **Power BI Setup:**
   - Launch Power BI Desktop.
   - Follow [power_bi/pbix_guide.md](power_bi/pbix_guide.md) to load the CSVs from `data/processed/` or use the Power Query M scripts in `power_bi/power_query_m/`.
4. **Excel Reconciliation:**
   - Open `excel/financial_assurance_reconciliation.xlsx` to inspect the 3-way financial reconciliation model.
