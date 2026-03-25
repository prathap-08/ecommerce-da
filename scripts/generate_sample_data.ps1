param(
    [int]$Seed = 42,
    [int]$CustomerCount = 500,
    [int]$OrderCount = 5000,
    [string]$OutputDir = "data"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Ensure deterministic output for reproducible analysis.
$random = [System.Random]::new($Seed)

$workspaceRoot = Split-Path -Parent $PSScriptRoot
$outPath = Join-Path $workspaceRoot $OutputDir
if (-not (Test-Path $outPath)) {
    New-Item -ItemType Directory -Path $outPath | Out-Null
}

$regions = @("North", "South", "East", "West", "Central")
$categories = @("Electronics", "Fashion", "Home", "Beauty", "Sports")

$catalogByCategory = @{
    "Electronics" = @("Wireless Earbuds", "Smartphone", "Bluetooth Speaker", "Laptop Backpack", "Smartwatch", "Power Bank")
    "Fashion" = @("Running Shoes", "Denim Jacket", "Cotton T-Shirt", "Analog Watch", "Sunglasses", "Casual Shirt")
    "Home" = @("Mixer Grinder", "Vacuum Cleaner", "Water Bottle", "Bedsheet Set", "Desk Lamp", "Storage Box")
    "Beauty" = @("Face Serum", "Hair Dryer", "Perfume", "Lipstick", "Body Lotion", "Beard Trimmer")
    "Sports" = @("Yoga Mat", "Dumbbell Set", "Cricket Bat", "Football", "Tennis Racket", "Cycling Gloves")
}

$firstNames = @("Aarav", "Vivaan", "Diya", "Isha", "Kabir", "Meera", "Rohan", "Anaya", "Arjun", "Kiara", "Neha", "Rahul")
$lastNames = @("Sharma", "Verma", "Patel", "Singh", "Khan", "Iyer", "Gupta", "Nair", "Reddy", "Jain", "Mehta", "Das")

# Build products table
$products = @()
$productIdCounter = 1
foreach ($category in $categories) {
    foreach ($productName in $catalogByCategory[$category]) {
        $productId = "P{0:d4}" -f $productIdCounter

        $basePrice = switch ($category) {
            "Electronics" { 1800 + $random.Next(200, 6500) }
            "Fashion" { 400 + $random.Next(100, 2600) }
            "Home" { 300 + $random.Next(100, 4500) }
            "Beauty" { 200 + $random.Next(50, 1800) }
            "Sports" { 350 + $random.Next(80, 3200) }
        }

        $price = [Math]::Round($basePrice, 2)
        $costFactor = 0.45 + ($random.NextDouble() * 0.35)
        $cost = [Math]::Round($price * $costFactor, 2)

        $products += [PSCustomObject]@{
            product_id = $productId
            product_name = $productName
            category = $category
            unit_price = $price
            unit_cost = $cost
        }

        $productIdCounter++
    }
}

# Build customer reference
$customers = @()
for ($i = 1; $i -le $CustomerCount; $i++) {
    $customerId = "C{0:d5}" -f $i
    $fullName = "$($firstNames[$random.Next(0, $firstNames.Count)]) $($lastNames[$random.Next(0, $lastNames.Count)])"
    $region = $regions[$random.Next(0, $regions.Count)]

    $customers += [PSCustomObject]@{
        customer_id = $customerId
        customer_name = $fullName
        home_region = $region
    }
}

$startDate = [datetime]"2024-01-01"
$endDate = [datetime]"2025-12-31"
$daySpan = ($endDate - $startDate).Days + 1

# Seasonality multipliers to create realistic highs/lows
$seasonality = @{
    1 = 0.92; 2 = 0.88; 3 = 0.95; 4 = 0.98; 5 = 1.02; 6 = 1.06;
    7 = 1.01; 8 = 1.03; 9 = 1.07; 10 = 1.15; 11 = 1.28; 12 = 1.35
}

$orders = @()
$sales = @()

for ($i = 1; $i -le $OrderCount; $i++) {
    $orderId = "O{0:d6}" -f $i

    $chosenCustomer = $customers[$random.Next(0, $customers.Count)]

    # Random date with weighted retries to respect seasonality.
    $pickedDate = $null
    for ($attempt = 0; $attempt -lt 10; $attempt++) {
        $candidate = $startDate.AddDays($random.Next(0, $daySpan))
        $monthFactor = $seasonality[$candidate.Month]
        if ($random.NextDouble() -le [Math]::Min($monthFactor / 1.4, 1.0)) {
            $pickedDate = $candidate
            break
        }
    }
    if ($null -eq $pickedDate) {
        $pickedDate = $startDate.AddDays($random.Next(0, $daySpan))
    }

    $orderRegion = $chosenCustomer.home_region

    $orders += [PSCustomObject]@{
        order_id = $orderId
        order_date = $pickedDate.ToString("yyyy-MM-dd")
        customer_id = $chosenCustomer.customer_id
        customer_name = $chosenCustomer.customer_name
        region = $orderRegion
    }

    # 1-4 lines per order.
    $lineCount = $random.Next(1, 5)
    $selectedProductIndexes = @{}

    for ($ln = 1; $ln -le $lineCount; $ln++) {
        do {
            $pidx = $random.Next(0, $products.Count)
        } while ($selectedProductIndexes.ContainsKey($pidx))
        $selectedProductIndexes[$pidx] = $true

        $product = $products[$pidx]

        $qty = $random.Next(1, 6)

        # Promotion windows (Jan and Jul) produce lower revenue per line.
        $discountRate = 0.0
        if ($pickedDate.Month -eq 1 -or $pickedDate.Month -eq 7) {
            $discountRate = 0.05 + ($random.NextDouble() * 0.20)
        } elseif ($pickedDate.Month -eq 11 -or $pickedDate.Month -eq 12) {
            $discountRate = 0.0 + ($random.NextDouble() * 0.08)
        } else {
            $discountRate = 0.01 + ($random.NextDouble() * 0.12)
        }

        $netUnitPrice = [Math]::Round($product.unit_price * (1 - $discountRate), 2)
        $lineRevenue = [Math]::Round($netUnitPrice * $qty, 2)

        $sales += [PSCustomObject]@{
            order_id = $orderId
            product_id = $product.product_id
            quantity = $qty
            revenue = $lineRevenue
        }
    }
}

# Export CSV files
$ordersFile = Join-Path $outPath "orders.csv"
$productsFile = Join-Path $outPath "products.csv"
$salesFile = Join-Path $outPath "sales.csv"

$orders | Export-Csv -Path $ordersFile -NoTypeInformation -Encoding UTF8
$products | Export-Csv -Path $productsFile -NoTypeInformation -Encoding UTF8
$sales | Export-Csv -Path $salesFile -NoTypeInformation -Encoding UTF8

Write-Output "Generated files:"
Write-Output "- $ordersFile"
Write-Output "- $productsFile"
Write-Output "- $salesFile"
Write-Output "Rows: orders=$($orders.Count), products=$($products.Count), sales=$($sales.Count)"
