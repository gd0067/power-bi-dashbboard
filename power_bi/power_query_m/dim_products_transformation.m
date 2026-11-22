// ============================================================================
// APEX RETAIL GLOBAL - POWER QUERY M CODE
// Table: dim_product
// Description: Product dimension transformation, margin tiers, and price bands.
// ============================================================================

let
    Source = Csv.Document(File.Contents("data/raw/raw_products_catalog.csv"),[Delimiter=",", Columns=9, Encoding=65001, QuoteStyle=QuoteStyle.None]),
    PromoteHeaders = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    TransformedTypes = Table.TransformColumnTypes(PromoteHeaders,{
        {"ProductID", type text},
        {"ProductName", type text},
        {"Category", type text},
        {"SubCategory", type text},
        {"UnitCost", type number},
        {"StandardPrice", type number},
        {"TargetMarginPct", type number},
        {"MinOrderQty", Int64.Type},
        {"IsDiscontinued", type text}
    }),

    // Add Price Tiering Band
    AddedPriceBand = Table.AddColumn(TransformedTypes, "PriceBand", each 
        if [StandardPrice] >= 1000 then "Premium Enterprise (>$1,000)"
        else if [StandardPrice] >= 300 then "Mid-Range ($300 - $1,000)"
        else "Standard Volume (<$300)", type text),

    // Add Target Margin Tier
    AddedMarginTier = Table.AddColumn(AddedPriceBand, "MarginTier", each 
        if [TargetMarginPct] >= 45 then "High Margin (>=45%)"
        else if [TargetMarginPct] >= 35 then "Balanced Margin (35-44%)"
        else "Volume Margin (<35%)", type text)
in
    AddedMarginTier
