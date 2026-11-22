// ============================================================================
// APEX RETAIL GLOBAL - POWER QUERY M CODE
// Function: fxCalendar_generator.m
// Description: Dynamic calendar generator with fiscal year, quarter, month,
//              day offsets, and weekend flags.
// ============================================================================

let
    GenerateCalendar = (StartDate as date, EndDate as date, optional FiscalYearStartMonth as number) =>
    let
        FYStartMonth = if FiscalYearStartMonth = null then 7 else FiscalYearStartMonth,
        DayCount = Duration.Days(Duration.From(EndDate - StartDate)) + 1,
        SourceDates = List.Dates(StartDate, DayCount, #duration(1, 0, 0, 0)),
        #"Converted to Table" = Table.FromList(SourceDates, Splitter.SplitByNothing(), {"Date"}, null, ExtraValues.Error),
        #"Changed Type" = Table.TransformColumnTypes(#"Converted to Table",{{"Date", type date}}),
        #"Added DateKey" = Table.AddColumn(#"Changed Type", "DateKey", each Date.Year([Date]) * 10000 + Date.Month([Date]) * 100 + Date.Day([Date]), Int64.Type),
        #"Added Year" = Table.AddColumn(#"Added DateKey", "Year", each Date.Year([Date]), Int64.Type),
        #"Added Quarter" = Table.AddColumn(#"Added Year", "Quarter", each "Q" & Text.From(Date.QuarterOfYear([Date])), type text),
        #"Added YearQuarter" = Table.AddColumn(#"Added Quarter", "YearQuarter", each Text.From(Date.Year([Date])) & "-Q" & Text.From(Date.QuarterOfYear([Date])), type text),
        #"Added MonthNum" = Table.AddColumn(#"Added YearQuarter", "MonthNum", each Date.Month([Date]), Int64.Type),
        #"Added MonthName" = Table.AddColumn(#"Added MonthNum", "MonthName", each Date.MonthName([Date]), type text),
        #"Added MonthShort" = Table.AddColumn(#"Added MonthName", "MonthShort", each Date.ToText([Date], "MMM"), type text),
        #"Added YearMonth" = Table.AddColumn(#"Added MonthShort", "YearMonth", each Date.ToText([Date], "yyyy-MM"), type text),
        #"Added DayOfWeek" = Table.AddColumn(#"Added YearMonth", "DayOfWeek", each Date.DayOfWeekName([Date]), type text),
        #"Added DayOfWeekNum" = Table.AddColumn(#"Added DayOfWeek", "DayOfWeekNum", each Date.DayOfWeek([Date], Day.Monday) + 1, Int64.Type),
        #"Added IsWeekend" = Table.AddColumn(#"Added DayOfWeekNum", "IsWeekend", each if [DayOfWeekNum] >= 6 then 1 else 0, Int64.Type),
        #"Added FiscalYear" = Table.AddColumn(#"Added IsWeekend", "FiscalYear", each 
            if [MonthNum] >= FYStartMonth 
            then "FY" & Text.From([Year] + 1) 
            else "FY" & Text.From([Year]), type text),
        #"Sorted Rows" = Table.Sort(#"Added FiscalYear",{{"Date", Order.Ascending}})
    in
        #"Sorted Rows"
in
    GenerateCalendar
