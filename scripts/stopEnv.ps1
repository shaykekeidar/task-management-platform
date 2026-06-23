# stopEnv.ps1

Write-Host "Stopping local environment..." -ForegroundColor Cyan

Write-Host ""
Write-Host "Stopping Minikube..." -ForegroundColor Cyan

minikube stop

if ($LASTEXITCODE -ne 0) {
    Write-Host "Minikube stop failed." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Environment stopped successfully." -ForegroundColor Green