param(
    [string]$DataDir = "data",
    [string]$OutputFile = "reports/insights_report.md"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$workspaceRoot = Split-Path -Parent $PSScriptRoot
$dataPath = Join-Path $workspaceRoot $DataDir
$outPath = Join-Path $workspaceRoot $OutputFile
$outDir = Split-Path -Parent $outPath
if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir | Out-Null
}

$ordersFile = Join-Path $dataPath "orders.csv"
$productsFile = Join-Path $dataPath "products.csv"
$salesFile = Join-Path $dataPath "sales.csv"

if (-not (Test-Path $ordersFile) -or -not (Test-Path $productsFile) -or -not (Test-Path $salesFile)) {
    throw "Missing CSV files in $dataPath. Run ./scripts/generate_sample_data.ps1 first."
}

$orders = Import-Csv $ordersFile
$products = Import-Csv $productsFile
$sales = Import-Csv $salesFile

$productById = @{}
foreach ($p in $products) { $productById[$p.product_id] = $p }

$orderById = @{}
foreach ($o in $orders) { $orderById[$o.order_id] = $o }

$enriched = @()
foreach ($s in $sales) {
    $o = $orderById[$s.order_id]
    $p = $productById[$s.product_id]
    if ($null -eq $o -or $null -eq $p) { continue }

    $qty = [int]$s.quantity
    $revenue = [double]$s.revenue
    $unitCost = [double]$p.unit_cost
    $profit = $revenue - ($unitCost * $qty)
    $date = [datetime]$o.order_date

    $enriched += [PSCustomObject]@{
        order_id = $o.order_id
        order_date = $date
        month_start = (Get-Date -Year $date.Year -Month $date.Month -Day 1)
        month_num = $date.Month
        customer_id = $o.customer_id
        customer_name = $o.customer_name
        region = $o.region
        product_id = $p.product_id
        product_name = $p.product_name
        category = $p.category
        quantity = $qty
        revenue = $revenue
        profit = $profit
    }
}

if ($enriched.Count -eq 0) {
    throw "No enriched rows found. Check source CSV integrity."
}

$totalRevenue = ($enriched | Measure-Object -Property revenue -Sum).Sum
$totalProfit = ($enriched | Measure-Object -Property profit -Sum).Sum
$totalUnits = ($enriched | Measure-Object -Property quantity -Sum).Sum
$totalOrders = ($orders | Select-Object -ExpandProperty order_id -Unique).Count
$aov = if ($totalOrders -gt 0) { $totalRevenue / $totalOrders } else { 0 }
$marginPct = if ($totalRevenue -ne 0) { 100 * ($totalProfit / $totalRevenue) } else { 0 }

$monthly = $enriched |
    Group-Object month_start |
    ForEach-Object {
        $monthRevenue = ($_.Group | Measure-Object -Property revenue -Sum).Sum
        $monthUnits = ($_.Group | Measure-Object -Property quantity -Sum).Sum
        [PSCustomObject]@{
            month_start = [datetime]$_.Name
            revenue = [double]$monthRevenue
            units = [int]$monthUnits
        }
    } |
    Sort-Object month_start

$monthlyWithMoM = @()
for ($i = 0; $i -lt $monthly.Count; $i++) {
    $curr = $monthly[$i]
    $prevRevenue = if ($i -gt 0) { [double]$monthly[$i - 1].revenue } else { $null }
    $mom = $null
    if ($null -ne $prevRevenue -and $prevRevenue -ne 0) {
        $mom = 100 * (($curr.revenue - $prevRevenue) / $prevRevenue)
    }

    $monthlyWithMoM += [PSCustomObject]@{
        month_start = $curr.month_start
        revenue = $curr.revenue
        units = $curr.units
        mom_growth_pct = $mom
    }
}

$seasonality = $enriched |
    Group-Object month_num |
    ForEach-Object {
        [PSCustomObject]@{
            month_num = [int]$_.Name
            avg_revenue = [double](($_.Group | Measure-Object -Property revenue -Average).Average)
        }
    } |
    Sort-Object month_num

$topProducts = $enriched |
    Group-Object product_id, product_name, category |
    ForEach-Object {
        $parts = $_.Name.Split(',').ForEach({ $_.Trim() })
        [PSCustomObject]@{
            product_id = $parts[0]
            product_name = $parts[1]
            category = $parts[2]
            total_revenue = [double](($_.Group | Measure-Object -Property revenue -Sum).Sum)
            total_units = [int](($_.Group | Measure-Object -Property quantity -Sum).Sum)
        }
    } |
    Sort-Object total_revenue -Descending |
    Select-Object -First 10

$regionSummary = $enriched |
    Group-Object region |
    ForEach-Object {
        $rev = [double](($_.Group | Measure-Object -Property revenue -Sum).Sum)
        $prof = [double](($_.Group | Measure-Object -Property profit -Sum).Sum)
        [PSCustomObject]@{
            region = $_.Name
            revenue = $rev
            profit = $prof
            margin_pct = if ($rev -ne 0) { 100 * ($prof / $rev) } else { 0 }
        }
    } |
    Sort-Object margin_pct -Descending

$topCustomers = $enriched |
    Group-Object customer_id, customer_name |
    ForEach-Object {
        $parts = $_.Name.Split(',').ForEach({ $_.Trim() })
        [PSCustomObject]@{
            customer_id = $parts[0]
            customer_name = $parts[1]
            lifetime_revenue = [double](($_.Group | Measure-Object -Property revenue -Sum).Sum)
            lifetime_units = [int](($_.Group | Measure-Object -Property quantity -Sum).Sum)
            orders_count = ($_.Group | Select-Object -ExpandProperty order_id -Unique).Count
        }
    } |
    Sort-Object lifetime_revenue -Descending |
    Select-Object -First 10

$dropMonths = $monthlyWithMoM | Where-Object { $null -ne $_.mom_growth_pct -and $_.mom_growth_pct -le -10 } | Sort-Object month_start

$lines = @()
$lines += "# E-commerce Sales Insights Report"
$lines += ""
$lines += "Generated on: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
$lines += ""
$lines += "## Executive KPIs"
$lines += "- Total Revenue: $([Math]::Round($totalRevenue, 2))"
$lines += "- Total Profit: $([Math]::Round($totalProfit, 2))"
$lines += "- Profit Margin %: $([Math]::Round($marginPct, 2))"
$lines += "- Total Orders: $totalOrders"
$lines += "- Units Sold: $totalUnits"
$lines += "- Average Order Value (AOV): $([Math]::Round($aov, 2))"
$lines += ""

$lines += "## Monthly Trend (Revenue, MoM %)"
$lines += "| Month | Revenue | MoM % |"
$lines += "|---|---:|---:|"
foreach ($m in $monthlyWithMoM) {
    $momText = if ($null -eq $m.mom_growth_pct) { "NA" } else { [Math]::Round($m.mom_growth_pct, 2) }
    $lines += "| $($m.month_start.ToString('yyyy-MM')) | $([Math]::Round($m.revenue, 2)) | $momText |"
}
$lines += ""

$lines += "## Seasonality (Average Revenue by Month Number)"
$lines += "| Month Number | Avg Revenue |"
$lines += "|---:|---:|"
foreach ($s in $seasonality) {
    $lines += "| $($s.month_num) | $([Math]::Round($s.avg_revenue, 2)) |"
}
$lines += ""

$lines += "## Top 10 Products by Revenue"
$lines += "| Product ID | Product Name | Category | Revenue | Units |"
$lines += "|---|---|---|---:|---:|"
foreach ($p in $topProducts) {
    $lines += "| $($p.product_id) | $($p.product_name) | $($p.category) | $([Math]::Round($p.total_revenue, 2)) | $($p.total_units) |"
}
$lines += ""

$lines += "## Region Profitability"
$lines += "| Region | Revenue | Profit | Margin % |"
$lines += "|---|---:|---:|---:|"
foreach ($r in $regionSummary) {
    $lines += "| $($r.region) | $([Math]::Round($r.revenue, 2)) | $([Math]::Round($r.profit, 2)) | $([Math]::Round($r.margin_pct, 2)) |"
}
$lines += ""

$lines += "## Top Customers by Lifetime Value"
$lines += "| Customer ID | Customer Name | LTV Revenue | Orders | Units |"
$lines += "|---|---|---:|---:|---:|"
foreach ($c in $topCustomers) {
    $lines += "| $($c.customer_id) | $($c.customer_name) | $([Math]::Round($c.lifetime_revenue, 2)) | $($c.orders_count) | $($c.lifetime_units) |"
}
$lines += ""

$lines += "## Sales Drop Alerts (MoM <= -10%)"
if ($dropMonths.Count -eq 0) {
    $lines += "- No months crossed the -10% drop threshold in this dataset."
} else {
    foreach ($d in $dropMonths) {
        $lines += "- $($d.month_start.ToString('yyyy-MM')): $([Math]::Round($d.mom_growth_pct, 2))%"
    }
}
$lines += ""

$lines += "## Possible Reasons for Low Months"
$lines += "- Reduced order volume and lower units sold in identified drop months."
$lines += "- Promotion-heavy months may reduce average selling price per unit."
$lines += "- Region/category mix shifts can reduce total revenue even when unit volume is stable."

Set-Content -Path $outPath -Value ($lines -join "`r`n") -Encoding UTF8
Write-Output "Generated report: $outPath"
