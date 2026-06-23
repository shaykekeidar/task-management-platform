# startEnv.ps1

Write-Host "Starting Minikube..." -ForegroundColor Cyan

minikube start

if ($LASTEXITCODE -ne 0) {
Write-Host "Minikube start failed. Purging and retrying with Hyper-V..." -ForegroundColor Yellow

```
minikube delete --all --purge
minikube start --driver=hyperv

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to start Minikube." -ForegroundColor Red
    exit 1
}
```

}

Write-Host ""
Write-Host "Creating ArgoCD namespace..." -ForegroundColor Cyan

kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

Write-Host ""
Write-Host "Installing ArgoCD..." -ForegroundColor Cyan

kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

Write-Host ""
Write-Host "Waiting for ArgoCD server deployment..." -ForegroundColor Cyan

kubectl rollout status deployment/argocd-server -n argocd --timeout=300s

Write-Host ""
Write-Host "Starting port-forward..." -ForegroundColor Cyan

Start-Process powershell -ArgumentList `    "-NoExit",`
"-Command", `
"kubectl port-forward svc/argocd-server -n argocd 8083:443"

Start-Sleep -Seconds 5


$encodedPassword = kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}"
$password = [System.Text.Encoding]::UTF8.GetString(
[System.Convert]::FromBase64String($encodedPassword)
)

Write-Host ""
Write-Host "========================================" -ForegroundColor Green
Write-Host "ArgoCD is ready" -ForegroundColor Green
Write-Host "========================================"
Write-Host ""
Write-Host "URL      : https://localhost:8083"
Write-Host "Username : admin"
Write-Host "Password : $password"
Write-Host ""
Write-Host "========================================" -ForegroundColor Green
