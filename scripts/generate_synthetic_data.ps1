# Complete Data Generation Script for Products, Stores, Orders, Targets and Processed Star Schema
$rng = [System.Random]::new(42)

Write-Host "Generating Products Catalog..."
$catalog = @(
    # Technology
    @{Cat="Technology"; Sub="Enterprise Servers"; Name="Optima Rackmount Server X800"; Cost=1450.0; Price=2400.0},
    @{Cat="Technology"; Sub="Enterprise Servers"; Name="EdgeCompute Blade Server B40"; Cost=980.0; Price=1650.0},
    @{Cat="Technology"; Sub="Networking"; Name="CoreFlow 48-Port Managed Switch"; Cost=420.0; Price=750.0},
    @{Cat="Technology"; Sub="Networking"; Name="SecureGate Enterprise Firewall Appliance"; Cost=650.0; Price=1150.0},
    @{Cat="Technology"; Sub="Networking"; Name="AeroWave High-Density Wi-Fi 6 AP"; Cost=180.0; Price=340.0},
    @{Cat="Technology"; Sub="Workstations & Laptops"; Name="Apex ProWorkstation Z-90"; Cost=1100.0; Price=1890.0},
    @{Cat="Technology"; Sub="Workstations & Laptops"; Name="UltraBook Latitude 14 Developer Ed"; Cost=720.0; Price=1250.0},
    @{Cat="Technology"; Sub="Workstations & Laptops"; Name="FieldTech Rugged Tablet 10.5"; Cost=410.0; Price=720.0},
    @{Cat="Technology"; Sub="Peripherals"; Name="UltraSharp 32-inch 4K Monitor"; Cost=290.0; Price=520.0},
    @{Cat="Technology"; Sub="Peripherals"; Name="ErgoType Mechanical Enterprise Keyboard"; Cost=45.0; Price=95.0},
    @{Cat="Technology"; Sub="Peripherals"; Name="PrecisionScan Biometric USB Hub"; Cost=60.0; Price=130.0},

    # Office Supplies & Equipment
    @{Cat="Office Supplies"; Sub="Storage & Filing"; Name="FireSafe Heavy-Duty 4-Drawer Cabinet"; Cost=180.0; Price=350.0},
    @{Cat="Office Supplies"; Sub="Storage & Filing"; Name="ArchiveBox High-Density Pack (50)"; Cost=35.0; Price=75.0},
    @{Cat="Office Supplies"; Sub="Paper Products"; Name="EcoWhite Multipurpose Copy Paper A4 Pallet"; Cost=210.0; Price=390.0},
    @{Cat="Office Supplies"; Sub="Paper Products"; Name="Premium Recycled Executive Bond Paper Box"; Cost=45.0; Price=88.0},
    @{Cat="Office Supplies"; Sub="Presentation"; Name="GlassBoard Magnetic Whiteboard 6x4ft"; Cost=110.0; Price=240.0},
    @{Cat="Office Supplies"; Sub="Presentation"; Name="LaserPoint Pro Wireless Presentation Remote"; Cost=22.0; Price=55.0},
    @{Cat="Office Supplies"; Sub="Mailing & Shipping"; Name="PolyMailer Weather-Resistant Mailers Pack (1000)"; Cost=65.0; Price=140.0},
    @{Cat="Office Supplies"; Sub="Mailing & Shipping"; Name="AutoTape Industrial Packing Dispenser"; Cost=30.0; Price=70.0},

    # Furniture
    @{Cat="Furniture"; Sub="Desks"; Name="Apex Electric Sit-Stand Desk 72x30"; Cost=380.0; Price=720.0},
    @{Cat="Furniture"; Sub="Desks"; Name="Modular Collaboration Executive Table"; Cost=550.0; Price=1050.0},
    @{Cat="Furniture"; Sub="Desks"; Name="Compact Workstation Cubicle Unit"; Cost=290.0; Price=580.0},
    @{Cat="Furniture"; Sub="Seating"; Name="ErgoMatrix Mesh Task Chair Pro"; Cost=190.0; Price=420.0},
    @{Cat="Furniture"; Sub="Seating"; Name="Executive Leather High-Back Swivel Chair"; Cost=260.0; Price=560.0},
    @{Cat="Furniture"; Sub="Seating"; Name="Conference Room Stacking Chairs (Set of 4)"; Cost=150.0; Price=320.0},
    @{Cat="Furniture"; Sub="Acoustics"; Name="SoundDampen Acoustic Privacy Divider Panel"; Cost=95.0; Price=210.0},

    # Industrial & Safety
    @{Cat="Industrial & Safety"; Sub="Protective Gear"; Name="ProShield Level 4 Cut-Resistant Gloves (Box of 50)"; Cost=60.0; Price=135.0},
    @{Cat="Industrial & Safety"; Sub="Protective Gear"; Name="VisionGuard Anti-Fog Industrial Goggles (Case of 24)"; Cost=75.0; Price=165.0},
    @{Cat="Industrial & Safety"; Sub="Facility Safety"; Name="SafeStep Anti-Fatigue Ergonomic Mat 3x5ft"; Cost=40.0; Price=95.0},
    @{Cat="Industrial & Safety"; Sub="Facility Safety"; Name="OmniSensor Carbon & Gas Alarm Commercial"; Cost=115.0; Price=240.0},
    @{Cat="Industrial & Safety"; Sub="Material Handling"; Name="HeavyDuty Hydraulic Pallet Jack 5500lb"; Cost=320.0; Price=650.0},
    @{Cat="Industrial & Safety"; Sub="Material Handling"; Name="StackPro Industrial Steel Shelving Unit"; Cost=140.0; Price=290.0}
)

$products = [System.Collections.Generic.List[PSCustomObject]]::new()
$pIndex = 1
foreach ($item in $catalog) {
    $productId = "PROD-" + $pIndex.ToString("D4")
    $products.Add([PSCustomObject]@{
        ProductID = $productId
        ProductName = $item.Name
        Category = $item.Cat
        SubCategory = $item.Sub
        UnitCost = [math]::Round($item.Cost, 2)
        StandardPrice = [math]::Round($item.Price, 2)
        TargetMarginPct = [math]::Round((($item.Price - $item.Cost) / $item.Price) * 100, 2)
        MinOrderQty = if ($item.Price -gt 500) { 1 } else { 5 }
        IsDiscontinued = if ($rng.NextDouble() -lt 0.05) { "Y" } else { "N" }
    })
    $pIndex++
}
$products | Export-Csv -Path "data\raw\raw_products_catalog.csv" -NoTypeInformation -Encoding UTF8
Write-Host "Products generated: $($products.Count)"

Write-Host "Generating Territories & Stores..."
$territoriesData = @(
    @{ID="STR-NA-01"; Name="New York Metro Regional Hub"; Channel="Direct Enterprise"; Region="North America"; Territory="US-Northeast"; Manager="Victoria Sterling"},
    @{ID="STR-NA-02"; Name="Chicago Midwest Logistics Hub"; Channel="Direct Enterprise"; Region="North America"; Territory="US-Midwest"; Manager="Arthur Pendelton"},
    @{ID="STR-NA-03"; Name="Dallas South Fulfillment Center"; Channel="Online B2B"; Region="North America"; Territory="US-South"; Manager="Elena Rostova"},
    @{ID="STR-NA-04"; Name="Silicon Valley Innovation Hub"; Channel="Direct Enterprise"; Region="North America"; Territory="US-West"; Manager="Marcus Vance"},
    @{ID="STR-NA-05"; Name="Seattle Pacific Distribution"; Channel="Retail Partner"; Region="North America"; Territory="US-Northwest"; Manager="Hannah Abbot"},
    @{ID="STR-NA-06"; Name="Toronto Eastern Canada Depot"; Channel="Direct Enterprise"; Region="North America"; Territory="CA-East"; Manager="Jean-Paul Tremblay"},
    @{ID="STR-NA-07"; Name="Vancouver Pacific Depot"; Channel="Online B2B"; Region="North America"; Territory="CA-West"; Manager="Fiona Gallagher"},
    @{ID="STR-EU-01"; Name="London Thames Gateway"; Channel="Direct Enterprise"; Region="Europe"; Territory="UK-South"; Manager="Alistair Finch"},
    @{ID="STR-EU-02"; Name="Frankfurt Central Hub"; Channel="Direct Enterprise"; Region="Europe"; Territory="EU-Central"; Manager="Klaus Hoffman"},
    @{ID="STR-EU-03"; Name="Amsterdam Port Logistics"; Channel="Online B2B"; Region="Europe"; Territory="EU-West"; Manager="Anouk Van Dijk"},
    @{ID="STR-EU-04"; Name="Paris Nord Distribution"; Channel="Retail Partner"; Region="Europe"; Territory="EU-Southwest"; Manager="Claire Dubois"},
    @{ID="STR-AP-01"; Name="Singapore Straits Gateway"; Channel="Direct Enterprise"; Region="Asia-Pacific"; Territory="APAC-SE"; Manager="Wei Chen"},
    @{ID="STR-AP-02"; Name="Sydney Botany Logistics Center"; Channel="Direct Enterprise"; Region="Asia-Pacific"; Territory="APAC-ANZ"; Manager="Damian Wright"},
    @{ID="STR-AP-03"; Name="Tokyo Kanto Center"; Channel="Online B2B"; Region="Asia-Pacific"; Territory="APAC-East"; Manager="Kenji Sato"}
)

$stores = [System.Collections.Generic.List[PSCustomObject]]::new()
foreach ($s in $territoriesData) {
    $stores.Add([PSCustomObject]@{
        StoreID = $s.ID
        StoreName = $s.Name
        Channel = $s.Channel
        Region = $s.Region
        TerritoryCode = $s.Territory
        RegionalManager = $s.Manager
        CapacityTier = if ($s.Channel -eq "Direct Enterprise") { "Tier 1 - Primary" } else { "Tier 2 - Satellite" }
        EstablishedYear = 2018 + $rng.Next(0, 4)
    })
}
$stores | Export-Csv -Path "data\raw\raw_territories_stores.csv" -NoTypeInformation -Encoding UTF8
Write-Host "Stores generated: $($stores.Count)"

Write-Host "Generating Transactions & Order Lines (2023 - 2024)..."
$customersList = Import-Csv -Path "data\raw\raw_customers.csv"

$startDate = [DateTime]::Parse("2023-01-02")
$endDate = [DateTime]::Parse("2024-12-30")
$totalDays = ($endDate - $startDate).Days

$orders = [System.Collections.Generic.List[PSCustomObject]]::new()
$orderItems = [System.Collections.Generic.List[PSCustomObject]]::new()
$assuranceLogs = [System.Collections.Generic.List[PSCustomObject]]::new()

$paymentStatuses = @("Paid in Full","Paid in Full","Paid in Full","Net 30 Pending","Net 60 Pending","Disputed Settlement")
$shipMethods = @("Express Air SLA-24","Standard Ground SLA-72","Dedicated Freight SLA-48","Economy Rail SLA-120")
$salesReps = @("Rachel Green","Harvey Specter","Donna Paulsen","Mike Ross","Louis Litt","Jessica Pearson","Robert Zane","Katrina Bennett")

$orderCount = 3800
$orderIDCounter = 10001
$itemCounter = 500001
$auditCounter = 80001

for ($i = 0; $i -lt $orderCount; $i++) {
    $orderID = "ORD-" + $orderIDCounter.ToString()
    $orderIDCounter++

    # Realistic seasonality: Q4 peak, steady growth in 2024
    $dayOffset = $rng.Next(0, $totalDays)
    $orderDate = $startDate.AddDays($dayOffset)
    $shipDays = $rng.Next(1, 7)
    $shipDate = $orderDate.AddDays($shipDays)

    $cust = $customersList[$rng.Next(0, $customersList.Count)]
    $store = $stores[$rng.Next(0, $stores.Count)]
    $rep = $salesReps[$rng.Next(0, $salesReps.Count)]
    $shipMethod = $shipMethods[$rng.Next(0, $shipMethods.Count)]
    
    # Assurance scenarios: payment dispute, delayed shipment
    $pStatus = $paymentStatuses[$rng.Next(0, $paymentStatuses.Count)]
    $isSlaBreached = if ($shipDays -gt 4 -and $shipMethod -match "SLA-24|SLA-48") { "Y" } else { "N" }

    $orders.Add([PSCustomObject]@{
        OrderID = $orderID
        OrderDate = $orderDate.ToString("yyyy-MM-dd")
        ShipDate = $shipDate.ToString("yyyy-MM-dd")
        CustomerID = $cust.CustomerID
        StoreID = $store.StoreID
        SalesRep = $rep
        PaymentStatus = $pStatus
        ShippingMethod = $shipMethod
        SlaBreachFlag = $isSlaBreached
    })

    # Line items for this order: 1 to 5 items
    $numLines = $rng.Next(1, 5)
    for ($line = 1; $line -le $numLines; $line++) {
        $prod = $products[$rng.Next(0, $products.Count)]
        $qty = $rng.Next(1, 15)
        
        # Base pricing
        $unitPrice = [double]$prod.StandardPrice
        $unitCost = [double]$prod.UnitCost

        # Assurance anomaly injection:
        # 1. Normal discount: 0% to 15%
        # 2. Rogue discount leakage (>25% up to 45% without manager authorization) ~4% of rows
        # 3. Negative margin breach (price sold below cost due to pricing glitch or unauthorized override) ~1.5% of rows
        $anomalyRoll = $rng.NextDouble()
        $auditReason = "None"
        $auditSeverity = "Normal"

        if ($anomalyRoll -lt 0.018) {
            # Negative margin breach
            $discountPct = [math]::Round(0.40 + ($rng.NextDouble() * 0.15), 2)
            $unitPrice = [math]::Round($unitCost * 0.88, 2) # sold below cost!
            $auditReason = "Negative Margin Anomaly"
            $auditSeverity = "Critical"
        } elseif ($anomalyRoll -lt 0.065) {
            # Discount leakage
            $discountPct = [math]::Round(0.25 + ($rng.NextDouble() * 0.20), 2)
            $auditReason = "Unauthorized Discount Leakage"
            $auditSeverity = "High"
        } else {
            # Normal commercial discount
            $discountPct = if ($rng.NextDouble() -lt 0.65) { [math]::Round($rng.NextDouble() * 0.12, 2) } else { 0.00 }
        }

        $grossRevenue = [math]::Round($unitPrice * $qty, 2)
        $discountAmount = [math]::Round($grossRevenue * $discountPct, 2)
        $netRevenue = [math]::Round($grossRevenue - $discountAmount, 2)
        $totalCost = [math]::Round($unitCost * $qty, 2)
        $grossMargin = [math]::Round($netRevenue - $totalCost, 2)
        $taxAmount = [math]::Round($netRevenue * 0.075, 2)
        $shippingCost = [math]::Round(12.50 + ($qty * 1.8), 2)

        $orderItems.Add([PSCustomObject]@{
            OrderItemID = "ITEM-" + $itemCounter.ToString()
            OrderID = $orderID
            LineNumber = $line
            ProductID = $prod.ProductID
            Quantity = $qty
            UnitCost = $unitCost
            UnitPrice = $unitPrice
            GrossRevenue = $grossRevenue
            DiscountPct = $discountPct
            DiscountAmount = $discountAmount
            NetRevenue = $netRevenue
            TotalCost = $totalCost
            GrossMargin = $grossMargin
            TaxAmount = $taxAmount
            ShippingCost = $shippingCost
            AuditFlag = $auditReason
        })

        if ($auditReason -ne "None" -or $isSlaBreached -eq "Y" -or $pStatus -eq "Disputed Settlement") {
            $logReason = if ($auditReason -ne "None") { $auditReason } elseif ($isSlaBreached -eq "Y") { "SLA Fulfillment Breach" } else { "Payment Dispute Risk" }
            $logSev = if ($auditReason -eq "Negative Margin Anomaly") { "Critical" } elseif ($auditReason -eq "Unauthorized Discount Leakage") { "High" } else { "Medium" }
            $financialExposure = if ($auditReason -eq "Negative Margin Anomaly") { [math]::Abs($grossMargin) } elseif ($auditReason -eq "Unauthorized Discount Leakage") { $discountAmount } else { $netRevenue }

            $assuranceLogs.Add([PSCustomObject]@{
                AuditLogID = "AUD-" + $auditCounter.ToString()
                OrderID = $orderID
                OrderItemID = "ITEM-" + $itemCounter.ToString()
                AuditDate = $orderDate.ToString("yyyy-MM-dd")
                AuditCategory = if ($auditReason -match "Discount|Margin") { "Commercial Pricing Risk" } elseif ($isSlaBreached -eq "Y") { "Operational SLA Risk" } else { "Credit & Settlement Risk" }
                AuditSeverity = $logSev
                AuditDescription = $logReason
                FinancialExposure = [math]::Round($financialExposure, 2)
                ResolutionStatus = if ($rng.NextDouble() -lt 0.72) { "Resolved - Mitigated" } else { "Under Executive Review" }
                Investigator = "Assurance Analytics Engine"
            })
            $auditCounter++
        }

        $itemCounter++
    }
}

$orders | Export-Csv -Path "data\raw\raw_orders_transactions.csv" -NoTypeInformation -Encoding UTF8
$orderItems | Export-Csv -Path "data\raw\raw_order_items.csv" -NoTypeInformation -Encoding UTF8
$assuranceLogs | Export-Csv -Path "data\processed\fact_assurance_audit_logs.csv" -NoTypeInformation -Encoding UTF8
Write-Host "Orders generated: $($orders.Count), Order Items: $($orderItems.Count), Assurance Audit Logs: $($assuranceLogs.Count)"

Write-Host "Generating Monthly Targets (2023 - 2024)..."
$targets = [System.Collections.Generic.List[PSCustomObject]]::new()
$categories = @("Technology","Office Supplies","Furniture","Industrial & Safety")

for ($yr = 2023; $yr -le 2024; $yr++) {
    for ($m = 1; $m -le 12; $m++) {
        $mDate = (Get-Date -Year $yr -Month $m -Day 1).ToString("yyyy-MM-dd")
        foreach ($store in $stores) {
            foreach ($cat in $categories) {
                # Target revenue base scaled by year (higher in 2024) and quarter
                $growthFactor = if ($yr -eq 2024) { 1.18 } else { 1.0 }
                $seasonFactor = if ($m -ge 10) { 1.35 } elseif ($m -ge 4 -and $m -le 6) { 1.1 } else { 0.95 }
                $baseRev = switch ($cat) {
                    "Technology" { 35000 }
                    "Furniture" { 22000 }
                    "Office Supplies" { 14000 }
                    "Industrial & Safety" { 16000 }
                }
                $targetRev = [math]::Round($baseRev * $growthFactor * $seasonFactor * (0.9 + ($rng.NextDouble() * 0.2)), 0)
                $targetMarginPct = switch ($cat) {
                    "Technology" { 38.0 }
                    "Furniture" { 48.0 }
                    "Office Supplies" { 42.0 }
                    "Industrial & Safety" { 52.0 }
                }
                $targetMarginAmt = [math]::Round($targetRev * ($targetMarginPct / 100), 0)

                $targets.Add([PSCustomObject]@{
                    TargetMonth = $mDate
                    StoreID = $store.StoreID
                    Category = $cat
                    TargetRevenue = $targetRev
                    TargetMarginAmount = $targetMarginAmt
                    TargetMarginPct = $targetMarginPct
                })
            }
        }
    }
}
$targets | Export-Csv -Path "data\raw\raw_targets_2023_2024.csv" -NoTypeInformation -Encoding UTF8
Write-Host "Targets generated: $($targets.Count)"

# Now generate processed Star Schema tables:
Write-Host "Exporting Clean Processed Dimensions & Facts for Star Schema..."
# Dim Customer
$customersList | Select-Object CustomerID, CustomerName, Segment, Country, Region, City, CreditRating, AccountStatus, OnboardingDate |
    Export-Csv -Path "data\processed\dim_customer.csv" -NoTypeInformation -Encoding UTF8

# Dim Product
$products | Select-Object ProductID, ProductName, Category, SubCategory, UnitCost, StandardPrice, TargetMarginPct, MinOrderQty, IsDiscontinued |
    Export-Csv -Path "data\processed\dim_product.csv" -NoTypeInformation -Encoding UTF8

# Dim Store
$stores | Select-Object StoreID, StoreName, Channel, Region, TerritoryCode, RegionalManager, CapacityTier, EstablishedYear |
    Export-Csv -Path "data\processed\dim_store.csv" -NoTypeInformation -Encoding UTF8

# Dim Date
$dates = [System.Collections.Generic.List[PSCustomObject]]::new()
$curr = [DateTime]::Parse("2023-01-01")
$endCalendar = [DateTime]::Parse("2024-12-31")
while ($curr -le $endCalendar) {
    $qtr = [math]::Ceiling($curr.Month / 3.0)
    # Fiscal Year starting July 1:
    $fy = if ($curr.Month -ge 7) { "FY" + ($curr.Year + 1).ToString() } else { "FY" + $curr.Year.ToString() }
    $dates.Add([PSCustomObject]@{
        Date = $curr.ToString("yyyy-MM-dd")
        DateKey = $curr.ToString("yyyyMMdd")
        Year = $curr.Year
        Quarter = "Q" + $qtr
        YearQuarter = $curr.Year.ToString() + "-Q" + $qtr
        MonthNum = $curr.Month
        MonthName = $curr.ToString("MMMM")
        MonthShort = $curr.ToString("MMM")
        YearMonth = $curr.ToString("yyyy-MM")
        DayOfWeek = $curr.ToString("dddd")
        DayOfWeekNum = [int]$curr.DayOfWeek
        IsWeekend = if ($curr.DayOfWeek -eq [DayOfWeek]::Saturday -or $curr.DayOfWeek -eq [DayOfWeek]::Sunday) { 1 } else { 0 }
        FiscalYear = $fy
    })
    $curr = $curr.AddDays(1)
}
$dates | Export-Csv -Path "data\processed\dim_date.csv" -NoTypeInformation -Encoding UTF8
Write-Host "Date dimension generated: $($dates.Count)"

# Fact Sales Orders (Flattened line-level fact table with foreign keys)
Write-Host "Joining and generating fact_sales_orders.csv..."
$ordersMap = @{}
foreach ($o in $orders) { $ordersMap[$o.OrderID] = $o }

$factSales = [System.Collections.Generic.List[PSCustomObject]]::new()
foreach ($item in $orderItems) {
    $o = $ordersMap[$item.OrderID]
    $dateKey = [DateTime]::Parse($o.OrderDate).ToString("yyyyMMdd")
    $factSales.Add([PSCustomObject]@{
        OrderItemID = $item.OrderItemID
        OrderID = $item.OrderID
        DateKey = $dateKey
        OrderDate = $o.OrderDate
        ShipDate = $o.ShipDate
        CustomerID = $o.CustomerID
        StoreID = $o.StoreID
        ProductID = $item.ProductID
        SalesRep = $o.SalesRep
        ShippingMethod = $o.ShippingMethod
        PaymentStatus = $o.PaymentStatus
        SlaBreachFlag = $o.SlaBreachFlag
        Quantity = $item.Quantity
        UnitCost = $item.UnitCost
        UnitPrice = $item.UnitPrice
        GrossRevenue = $item.GrossRevenue
        DiscountPct = $item.DiscountPct
        DiscountAmount = $item.DiscountAmount
        NetRevenue = $item.NetRevenue
        TotalCost = $item.TotalCost
        GrossMargin = $item.GrossMargin
        TaxAmount = $item.TaxAmount
        ShippingCost = $item.ShippingCost
        AuditFlag = $item.AuditFlag
    })
}
$factSales | Export-Csv -Path "data\processed\fact_sales_orders.csv" -NoTypeInformation -Encoding UTF8
Write-Host "Fact Sales generated: $($factSales.Count)"
Write-Host "Data generation complete!"
