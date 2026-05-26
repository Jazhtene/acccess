# Start ACCESS VisionCheck FastAPI on port 3001 (required for Flutter Web + Mobile)
Set-Location $PSScriptRoot\..\access_backend
Write-Host "Starting ACCESS backend at http://127.0.0.1:3001 ..."
Write-Host "Health check: http://127.0.0.1:3001/api/health"
Write-Host ""
python manage.py runserver
