# DAX Formula & Measure Reference Guide
**Organization:** Apex Retail Global  
**Author:** Lead BI Developer & Financial Assurance Architect  

---

## 1. Overview & Best Practices

All business logic in this model is authored as **explicit DAX measures** (never implicit drag-and-drop aggregations). Key standards enforced:
1. **Always use `DIVIDE()` instead of `/`** to prevent divide-by-zero runtime errors and return customizable alternates (or clean blanks).
2. **Qualify column references with table names** (e.g., `fact_sales_orders[NetRevenue]`) and **measures without table names** (e.g., `[Total Net Revenue]`), adhering strictly to Italian DAX formatting conventions.
3. **Minimize row-by-row iteration:** Use vector-optimized aggregators (`SUM`, `AVERAGE`) where possible; restrict `SUMX` and `AVERAGEX` to required row-level dynamic expressions.
4. **Leverage Variables (`VAR ... RETURN`):** Improves readability and forces single-pass calculation of intermediate results rather than re-evaluating expressions inside conditional branches.

---

## 2. Core Commercial & Financial Measures

### `[Total Net Revenue]`
```dax
Total Net Revenue = 
SUM ( fact_sales_orders[NetRevenue] )
```
- **Business Definition:** Top-line recognized sales revenue net of commercial discounts, before sales tax and shipping surcharges.
- **Context:** Evaluates dynamically against any filtered slice of `dim_date`, `dim_customer`, `dim_product`, or `dim_store`.

### `[Gross Margin]`
```dax
Gross Margin = 
[Total Net Revenue] - [Total Cost]
```
- **Business Definition:** Realized gross operating profit dollars generated after subtracting Cost of Goods Sold (COGS).

### `[Gross Margin %]`
```dax
Gross Margin % = 
DIVIDE ( 
    [Gross Margin], 
    [Total Net Revenue], 
    0 
)
```
- **Business Definition:** Gross margin efficiency percentage. Used as the primary benchmark against product target margin percentages.

### `[Average Order Value]`
```dax
Average Order Value = 
DIVIDE ( 
    [Total Net Revenue], 
    DISTINCTCOUNT ( fact_sales_orders[OrderID] ), 
    0 
)
```
- **Business Definition:** Commercial basket size indicator. Distinguishes high-volume, low-margin transactions from enterprise deal volume.

---

## 3. Time Intelligence & Variance Measures

### `[Revenue YTD]`
```dax
Revenue YTD = 
TOTALYTD ( 
    [Total Net Revenue], 
    dim_date[Date] 
)
```
- **Evaluation Engine:** Calculates cumulative calendar year-to-date revenue starting on January 1st and resetting on December 31st.

### `[Revenue SPLY]` (Same Period Last Year)
```dax
Revenue SPLY = 
CALCULATE ( 
    [Total Net Revenue], 
    SAMEPERIODLASTYEAR ( dim_date[Date] ) 
)
```
- **Evaluation Engine:** Shifts the current filter context back exactly one calendar year along the official date dimension.

### `[YoY Revenue Growth %]`
```dax
YoY Revenue Growth % = 
VAR _Current = [Total Net Revenue]
VAR _Prior = [Revenue SPLY]
RETURN
    DIVIDE ( 
        _Current - _Prior, 
        _Prior, 
        BLANK () 
    )
```
- **Business Meaning:** Growth rate against the equivalent prior year period. Returns `BLANK()` for baseline years (2023) where prior period records do not exist, eliminating skewed percentages.

### `[3M Rolling Avg Revenue]`
```dax
3M Rolling Avg Revenue = 
AVERAGEX ( 
    DATESINPERIOD ( 
        dim_date[Date], 
        LASTDATE ( dim_date[Date] ), 
        -3, 
        MONTH 
    ), 
    [Total Net Revenue] 
)
```
- **Evaluation Engine:** Smooths month-to-month seasonal spikes by computing the unweighted average of the prior 90-day moving window.

---

## 4. Revenue Assurance, Anomaly & Audit Measures

### `[Discount Leakage Amount]`
```dax
Discount Leakage Amount = 
CALCULATE ( 
    SUM ( fact_sales_orders[DiscountAmount] ), 
    fact_sales_orders[DiscountPct] >= 0.25 
)
```
- **Audit Logic:** Flags all transactions where a sales discount was executed at or above 25% (exceeding standard commercial delegation of authority without VP Finance written override).

### `[Negative Margin Loss]`
```dax
Negative Margin Loss = 
CALCULATE ( 
    SUMX ( 
        FILTER ( fact_sales_orders, fact_sales_orders[GrossMargin] < 0 ), 
        ABS ( fact_sales_orders[GrossMargin] ) 
    ) 
)
```
- **Audit Logic:** Calculates the absolute dollar loss incurred by selling products beneath base COGS.

### `[Assurance Compliance Health Score]`
```dax
Assurance Compliance Health Score = 
VAR _LeakagePenalty = [Discount Leakage Ratio %] * 150
VAR _MarginPenalty = DIVIDE ( [Negative Margin Order Count], [Total Line Items], 0 ) * 200
VAR _SlaPenalty = [SLA Breach Rate %] * 100
VAR _RawScore = 100 - ( _LeakagePenalty + _MarginPenalty + _SlaPenalty )
RETURN
    MAX ( 0, MIN ( 100, ROUND ( _RawScore, 1 ) ) )
```
- **Audit Logic:** Composite index (0–100) scoring operational and commercial discipline. A score below 85 automatically triggers senior management warning callouts on executive dashboards.
