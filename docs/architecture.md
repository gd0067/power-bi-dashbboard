# Data Architecture & Star Schema Design
**Project:** Apex Retail Global Analytics & Assurance  
**Author:** Business Intelligence & Enterprise Data Engineering Team  
**Design Standard:** Kimball Dimensional Modeling Methodology

---

## 1. Architectural Philosophy

The enterprise analytics platform uses a modern, layered data architecture to ensure data integrity, performant aggregation, and complete audit assurance.

```
┌─────────────────────────────────┐
│     RAW TRANSACTIONAL SOURCES   │
│  - ERP Order System (CSV/API)   │
│  - CRM Customer Accounts        │
│  - Logistics Fulfillment Logs   │
└─────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────┐
│       STAGING LAYER (stg)       │
│  - Ingestion Validation         │
│  - Type Casting & Deduplication │
│  - Data Cleaning & Normalization│
└─────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────┐
│      ENTERPRISE DWH (edw)       │
│      Strict Star Schema         │
│  - FactSalesOrders              │
│  - FactAssuranceAuditLogs       │
│  - Conformed Dimensions (4)     │
└─────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────┐
│    POWER BI TABULAR ENGINE      │
│  - In-Memory VertiPaq Model     │
│  - Explicit DAX Measure Layer   │
│  - Role-Playing Dimensions      │
│  - 4-Tier Interactive Dashboard │
└─────────────────────────────────┘
```

---

## 2. Kimball Dimensional Model & Grain Selection

### 2.1 Fact Table Grain
- **Table:** `edw.FactSalesOrders`
- **Grain:** **One individual line item per customer sales transaction**.
- **Rationale:** Line-item granularity is mandatory for financial assurance. Order-level aggregation conceals rogue single-product discounts, negative margin overrides, and SKU-level supply chain SLA failures.

### 2.2 Conformed Dimensions
1. **`edw.DimDate`**:
   - Single source of truth for chronological filtering.
   - Distinct from system auto-datetime hierarchies, enabling cross-table time intelligence (`SAMEPERIODLASTYEAR`, `TOTALYTD`).
2. **`edw.DimCustomer`**:
   - Contains customer demographics, commercial segment, and credit rating tiers.
   - Built to accommodate Slowly Changing Dimensions (SCD Type 1 for address updates; SCD Type 2 foundation with `IsCurrent` and `EffectiveDate`).
3. **`edw.DimProduct`**:
   - Hierarchical merchandise taxonomy: Category -> SubCategory -> Product.
   - Houses baseline standard prices and target gross margins for variance auditing.
4. **`edw.DimStore`**:
   - Hub and territory dimension linking physical distribution centers and sales channels (Direct Enterprise, Online B2B, Retail Partner).

---

## 3. Modeling Best Practices Implemented

- **No Bi-Directional Cross-Filtering:** All relationships are strictly `1:*` single-directional from Dimensions to Facts. This prevents circular dependency paths, ambiguous filter propagation, and VertiPaq performance degradation.
- **Surrogate Keys vs Natural Keys:** Integer surrogate keys (`DateKey`, `CustomerKey`, `ProductKey`, `StoreKey`) are indexed with clustered and non-clustered indexes for lightning-fast join execution in SQL and optimal dictionary encoding in VertiPaq.
- **Degenerate Dimensions:** `OrderID` is preserved in the fact table without creating a bloated header table, enabling order-level distinct counts and drill-through navigation.
- **Audit Separation:** While operational metrics live on `FactSalesOrders`, critical audit events are logged in `FactAssuranceAuditLogs` for governance tracking and remediation sign-off.
