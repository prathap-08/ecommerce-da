Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$workspace = Split-Path -Parent $PSScriptRoot
$pythonExe = Join-Path $workspace ".venv\Scripts\python.exe"

if (-not (Test-Path $pythonExe)) {
    throw "Python executable not found at $pythonExe"
}

Set-Location $workspace

& $pythonExe .\scripts\generate_enterprise_data.py --rows 120000 --customers 20000 --products 600 --seed 42
if ($LASTEXITCODE -ne 0) { throw "generate_enterprise_data.py failed with exit code $LASTEXITCODE" }
& $pythonExe .\analytics\etl_pipeline.py
if ($LASTEXITCODE -ne 0) { throw "etl_pipeline.py failed with exit code $LASTEXITCODE" }
& $pythonExe .\analytics\run_analysis.py
if ($LASTEXITCODE -ne 0) { throw "run_analysis.py failed with exit code $LASTEXITCODE" }
& $pythonExe .\analytics\advanced_models.py
if ($LASTEXITCODE -ne 0) { throw "advanced_models.py failed with exit code $LASTEXITCODE" }
& $pythonExe .\analytics\generate_executive_report.py
if ($LASTEXITCODE -ne 0) { throw "generate_executive_report.py failed with exit code $LASTEXITCODE" }
& $pythonExe .\analytics\export_rfm_for_crm.py
if ($LASTEXITCODE -ne 0) { throw "export_rfm_for_crm.py failed with exit code $LASTEXITCODE" }
& $pythonExe .\analytics\generate_board_ppt.py
if ($LASTEXITCODE -ne 0) { throw "generate_board_ppt.py failed with exit code $LASTEXITCODE" }

Write-Output "Full pipeline executed successfully."
