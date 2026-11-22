// ============================================================================
// APEX RETAIL GLOBAL - POWER QUERY M CODE
// Table: fact_sales_orders
// Description: Ingestion and transformation script for transactional sales data.
// ============================================================================

let
    // 1. Ingest raw CSV files
    SourceOrders = Csv.Document(File.Contents("data/raw/raw_orders_transactions.csv"),[Delimiter=",", Columns=9, Encoding=65001, QuoteStyle=QuoteStyle.None]),
    PromoteHeadersOrders = Table.PromoteHeaders(SourceOrders, [PromoteAllScalars=true]),
    
    SourceItems = Csv.Document(File.Contents("data/raw/raw_order_items.csv"),[Delimiter=",", Columns=16, Encoding=65001, QuoteStyle=QuoteStyle.None]),
    PromoteHeadersItems = Table.PromoteHeaders(SourceItems, [PromoteAllScalars=true]),

    // 2. Merge Orders and Order Items on OrderID
    MergedQueries = Table.NestedJoin(PromoteHeadersItems, {"OrderID"}, PromoteHeadersOrders, {"OrderID"}, "OrderHeader", JoinKind.Inner),
    ExpandedHeader = Table.ExpandTableColumn(MergedQueries, "OrderHeader", 
        {"OrderDate", "ShipDate", "CustomerID", "StoreID", "SalesRep", "PaymentStatus", "ShippingMethod", "SlaBreachFlag"}, 
        {"OrderDate", "ShipDate", "CustomerID", "StoreID", "SalesRep", "PaymentStatus", "ShippingMethod", "SlaBreachFlag"}),

    // 3. Transform Data Types
    TransformedTypes = Table.TransformColumnTypes(ExpandedHeader,{
        {"OrderItemID", type text},
        {"OrderID", type text},
        {"LineNumber", Int64.Type},
        {"ProductID", type text},
        {"Quantity", Int64.Type},
        {"UnitCost", type number},
        {"UnitPrice", type number},
        {"GrossRevenue", type number},
        {"DiscountPct", type number},
        {"DiscountAmount", type number},
        {"NetRevenue", type number},
        {"TotalCost", type number},
        {"GrossMargin", type number},
        {"TaxAmount", type number},
        {"ShippingCost", type number},
        {"AuditFlag", type text},
        {"OrderDate", type date},
        {"ShipDate", type date},
        {"CustomerID", type text},
        {"StoreID", type text},
        {"SalesRep", type text},
        {"PaymentStatus", type text},
        {"ShippingMethod", type text},
        {"SlaBreachFlag", type text}
    }),

    // 4. Add DateKey for Star Schema Relationship
    AddedDateKey = Table.AddColumn(TransformedTypes, "DateKey", each 
        Date.Year([OrderDate]) * 10000 + Date.Month([OrderDate]) * 100 + Date.Day([OrderDate]), Int64.Type),

    // 5. Add Audit Risk Classification Flag
    AddedRiskCategory = Table.AddColumn(AddedDateKey, "RiskCategory", each 
        if [GrossMargin] < 0 then "Critical - Negative Margin"
        else if [DiscountPct] >= 0.25 then "High - Unauthorized Discount"
        else if [PaymentStatus] = "Disputed Settlement" then "High - Disputed Settlement"
        else if [SlaBreachFlag] = "Y" then "Medium - SLA Delay"
        else "Normal Operation", type text)
in
    AddedRiskCategory
