# startEnv.ps1

Write-Host "Starting Minikube..." -ForegroundColor Cyan

minikube start

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "Minikube start failed. Retrying once..." -ForegroundColor Yellow

    minikube stop
    minikube start

    if ($LASTEXITCODE -ne 0) {
        Write-Host ""
        Write-Host "Minikube still failed to start." -ForegroundColor Red
        Write-Host "The cluster was not deleted automatically." -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Diagnostic commands:"
        Write-Host "  minikube status"
        Write-Host "  minikube logs"
        Write-Host ""
        Write-Host "Use 'minikube delete --all --purge' manually only if you decide to recreate the cluster."
        exit 1
    }
}

Write-Host ""
Write-Host "Waiting for Minikube node..." -ForegroundColor Cyan

kubectl wait --for=condition=Ready node/minikube --timeout=180s

if ($LASTEXITCODE -ne 0) {
    Write-Host "Minikube node did not become ready." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Ensuring Minikube primary-node label..." -ForegroundColor Cyan

kubectl label node minikube minikube.k8s.io/primary=true --overwrite

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to configure Minikube node label." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Enabling ingress addon..." -ForegroundColor Cyan

minikube addons enable ingress

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to enable the ingress addon." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Waiting for ingress controller..." -ForegroundColor Cyan

kubectl rollout status deployment/ingress-nginx-controller `
    -n ingress-nginx `
    --timeout=300s

if ($LASTEXITCODE -ne 0) {
    Write-Host "Ingress controller did not become ready." -ForegroundColor Red

    kubectl get pods -n ingress-nginx -o wide
    kubectl get events -n ingress-nginx `
        --sort-by=.metadata.creationTimestamp

    exit 1
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

Start-Process powershell -ArgumentList `
    "-NoExit",
    "-Command",
    "kubectl port-forward svc/argocd-server -n argocd 8083:443"

Start-Sleep -Seconds 5


$encodedPassword = kubectl get secret argocd-initial-admin-secret `
    -n argocd `
    -o jsonpath="{.data.password}" `
    2>$null

if ($LASTEXITCODE -eq 0 -and $encodedPassword) {
    $password = [System.Text.Encoding]::UTF8.GetString(
        [System.Convert]::FromBase64String($encodedPassword)
    )
}
else {
    $password = "<existing ArgoCD password>"
}

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
