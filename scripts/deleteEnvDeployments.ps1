param(
    [ValidateSet("dev", "test")]
    [string]$Environment
)

function Show-Help {
    Write-Host ""
    Write-Host "Usage:"
    Write-Host "  .\deleteEnvDeployments.ps1 dev"
    Write-Host "  .\deleteEnvDeployments.ps1 test"
    Write-Host ""
}

if (-not $Environment) {
    Show-Help
    exit 1
}

$Namespace = "task-generator-$Environment"

Write-Host "Deleting deployments from namespace: $Namespace"
Write-Host ""

kubectl delete deployment frontend-deployment -n $Namespace --ignore-not-found
kubectl delete deployment users-deployment -n $Namespace --ignore-not-found
kubectl delete deployment auth-deployment -n $Namespace --ignore-not-found
kubectl delete deployment tasks-deployment -n $Namespace --ignore-not-found

if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to delete one or more deployments"
    exit 1
}

Write-Host ""
Write-Host "Deployments deleted from $Namespace"