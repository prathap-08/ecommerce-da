param(
    [string]$OrdersCsv = "data/orders.csv",
    [string]$OutputCsv = "data/date_dimension.csv"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$workspaceRoot = Split-Path -Parent $PSScriptRoot
$ordersPath = Join-Path $workspaceRoot $OrdersCsv
$outPath = Join-Path $workspaceRoot $OutputCsv
$outDir = Split-Path -Parent $outPath
if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Path $outDir | Out-Null
}

if (Test-Path $ordersPath) {
    $orders = Import-Csv $ordersPath
    $dates = $orders | ForEach-Object { [datetime]$_.order_date }
    $minDate = ($dates | Measure-Object -Minimum).Minimum.Date
    $maxDate = ($dates | Measure-Object -Maximum).Maximum.Date
} else {
    $minDate = [datetime]"2024-01-01"
    $maxDate = [datetime]"2025-12-31"
}

$rows = @()
$current = $minDate
while ($current -le $maxDate) {
    $dayOfWeek = [int]$current.DayOfWeek
    $isWeekend = if ($dayOfWeek -eq 0 -or $dayOfWeek -eq 6) { 1 } else { 0 }

    $rows += [PSCustomObject]@{
        date_key = $current.ToString("yyyyMMdd")
        date = $current.ToString("yyyy-MM-dd")
        year = $current.Year
        quarter = "Q$([int][Math]::Ceiling($current.Month / 3.0))"
        month_num = $current.Month
        month_name = $current.ToString("MMMM")
        week_of_year = [System.Globalization.CultureInfo]::InvariantCulture.Calendar.GetWeekOfYear(
            $current,
            [System.Globalization.CalendarWeekRule]::FirstFourDayWeek,
            [DayOfWeek]::Monday
        )
        day_of_month = $current.Day
        day_name = $current.ToString("dddd")
        is_weekend = $isWeekend
    }

    $current = $current.AddDays(1)
}

$rows | Export-Csv -Path $outPath -NoTypeInformation -Encoding UTF8
Write-Output "Generated: $outPath (rows=$($rows.Count))"
