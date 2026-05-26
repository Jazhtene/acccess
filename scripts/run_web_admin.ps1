# Start backend + Flutter Web admin (uses config/api.json for API URL)
$root = Split-Path $PSScriptRoot -Parent
Set-Location $root

Write-Host "Starting backend on port 3001..."
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd '$root\access_backend'; python manage.py runserver"

Start-Sleep -Seconds 3

Write-Host "Starting Flutter Web admin (API: http://127.0.0.1:3001)..."
flutter run -d chrome --dart-define-from-file=config/api.json
