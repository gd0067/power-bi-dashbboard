// ============================================================================
// APEX RETAIL GLOBAL - POWER QUERY M CODE
// Table: dim_customer
// Description: Customer dimension cleansing, segmentation, and credit risk tiering.
// ============================================================================

let
    Source = Csv.Document(File.Contents("data/raw/raw_customers.csv"),[Delimiter=",", Columns=9, Encoding=65001, QuoteStyle=QuoteStyle.None]),
    PromoteHeaders = Table.PromoteHeaders(Source, [PromoteAllScalars=true]),
    TransformedTypes = Table.TransformColumnTypes(PromoteHeaders,{
        {"CustomerID", type text},
        {"CustomerName", type text},
        {"Segment", type text},
        {"Country", type text},
        {"Region", type text},
        {"City", type text},
        {"CreditRating", type text},
        {"AccountStatus", type text},
        {"OnboardingDate", type date}
    }),

    // Add Credit Risk Tier
    AddedCreditRiskTier = Table.AddColumn(TransformedTypes, "CreditRiskTier", each 
        if [CreditRating] = "AAA" or [CreditRating] = "AA" then "Prime / Low Risk"
        else if [CreditRating] = "A" then "Standard / Moderate Risk"
        else "Subprime / Elevated Risk", type text),

    // Cleanse trailing whitespaces
    TrimmedColumns = Table.TransformColumns(AddedCreditRiskTier, {
        {"CustomerName", Text.Trim, type text},
        {"City", Text.Trim, type text}
    })
in
    TrimmedColumns
