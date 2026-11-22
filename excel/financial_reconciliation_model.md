# Financial Reconciliation & Assurance Model (Excel)
**Organization:** Apex Retail Global  
**Workbook:** `excel/financial_assurance_reconciliation.xlsx`  
**Purpose:** Triangulate and reconcile ERP transactional source data against SQL Data Warehouse tables and Power BI Tabular Data Models to guarantee 100% financial assurance.

---

## 1. Reconciliation Methodology & Pipeline

In enterprise financial assurance, reporting systems must undergo formal reconciliation audits before senior stakeholders or external auditors rely on executive dashboards.

```
┌──────────────────┐       ETL Staging       ┌──────────────────┐
│ ERP Transactions │ ──────────────────────> │ SQL Data Whse    │
│ (Raw Extracts)   │                         │ (Star Schema)    │
└──────────────────┘                         └──────────────────┘
         │                                             │
         │                                             │ Direct Import /
         │                                             │ Tabular Cache
         ▼                                             ▼
┌───────────────────────────────────────────────────────────────┐
│               EXCEL 3-WAY FINANCIAL RECONCILIATION            │
│               - Variance Analysis (ERP vs EDW) = $0.00        │
│               - Variance Analysis (EDW vs PBI) = $0.00        │
│               - 100% Audited Financial Traceability           │
└───────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
                     ┌───────────────────────┐
                     │ Power BI Dashboard    │
                     │ Executive Assurance   │
                     └───────────────────────┘
```

---

## 2. Cross-System Reconciliation Matrix

The table below reflects the verified values embedded in `financial_assurance_reconciliation.xlsx`:

| Financial Metric / Dimension | ERP Raw Source | SQL Staging Layer | SQL EDW Fact | Power BI Model | Variance (ERP - EDW) | Variance (EDW - PBI) | Audit Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Total Gross Sales ($)** | \$20,124,850.00 | \$20,124,850.00 | \$20,124,850.00 | \$20,124,850.00 | \$0.00 | \$0.00 | **100% RECONCILED** |
| **Commercial Discounts ($)** | \$1,672,660.00 | \$1,672,660.00 | \$1,672,660.00 | \$1,672,660.00 | \$0.00 | \$0.00 | **100% RECONCILED** |
| **Total Net Revenue ($)** | \$18,452,190.00 | \$18,452,190.00 | \$18,452,190.00 | \$18,452,190.00 | \$0.00 | \$0.00 | **100% RECONCILED** |
| **Cost of Goods Sold - COGS ($)** | \$10,609,650.00 | \$10,609,650.00 | \$10,609,650.00 | \$10,609,650.00 | \$0.00 | \$0.00 | **100% RECONCILED** |
| **Gross Margin ($)** | \$7,842,540.00 | \$7,842,540.00 | \$7,842,540.00 | \$7,842,540.00 | \$0.00 | \$0.00 | **100% RECONCILED** |
| **Total Sales Order Volume** | 3,800 | 3,800 | 3,800 | 3,800 | 0 | 0 | **100% RECONCILED** |
| **Total Transaction Line Items** | 9,442 | 9,442 | 9,442 | 9,442 | 0 | 0 | **100% RECONCILED** |

---

## 3. Dynamic Excel Formulas Used

1. **Cross-System Dynamic Variance:**
   ```excel
   =C6 - D6
   ```
2. **Automated Audit Compliance Trigger:**
   ```excel
   =IF(AND(F6=0, G6=0), "100% RECONCILED - ZERO VARIANCE", "AUDIT INVESTIGATION REQUIRED")
   ```
3. **Discount Leakage Rate %:**
   ```excel
   =LET(
       gross, SUMIFS(FactSales[GrossRevenue], FactSales[Year], 2024),
       discount, SUMIFS(FactSales[DiscountAmount], FactSales[Year], 2024),
       IF(gross > 0, discount / gross, 0)
   )
   ```
4. **Customer Credit Risk Exposure Lookup:**
   ```excel
   =XLOOKUP(A5, DimCustomer[CustomerID], DimCustomer[CreditRating], "Unrated", 0)
   ```
