Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$workspace = Split-Path -Parent $PSScriptRoot
$pythonExe = Join-Path $workspace ".venv\Scripts\python.exe"

if (-not (Test-Path $pythonExe)) {
    throw "Python executable not found at $pythonExe"
}

Set-Location $workspace
& $pythonExe -m uvicorn backend.main:app --host 127.0.0.1 --port 8000 --reload
