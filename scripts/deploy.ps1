```powershell
param(
    [ValidateSet("users", "auth", "tasks", "frontend")]
    [string]$Application
)

function Show-Help {
    Write-Host ""
    Write-Host "========================================"
    Write-Host " Kubernetes Manual CI/CD Deployment"
    Write-Host "========================================"
    Write-Host ""
    Write-Host "Usage:"
    Write-Host "  .\deploy.ps1 users"
    Write-Host "  .\deploy.ps1 auth"
    Write-Host "  .\deploy.ps1 tasks"
    Write-Host "  .\deploy.ps1 frontend"
    Write-Host ""
}

function Test-DockerTagExists {
    param([string]$Image)

    docker manifest inspect $Image *> $null
    return ($LASTEXITCODE -eq 0)
}

if (-not $Application) {
    Show-Help
    exit 1
}

$RootPath = "D:\Kubernetes\kub-network-01-starting-setup"
$VersionFile = "$RootPath\app\application-versions.txt"

$Versions = @{}

Get-Content $VersionFile | ForEach-Object {
    if ($_ -match "^\s*([^=]+)\s*=\s*(\d+)\s*$") {
        $Versions[$matches[1].Trim()] = $matches[2].Trim()
    }
}

$Version = $Versions[$Application]

if (-not $Version) {
    Write-Error "Version for '$Application' not found in $VersionFile"
    exit 1
}

$ConfigMapFile = $null
$DeploymentName = $null

switch ($Application) {
    "users" {
        $DockerRepo = "shaykekeidar/kub-demo-users"
        $AppFolder = "$RootPath\app\users-api"
        $DeploymentFile = "$RootPath\k8s-raw-yaml\users\users-deployment.yaml"
        $EnvVariable = "USERS_VERSION"
        $DeploymentName = "users-deployment"
    }

    "auth" {
        $DockerRepo = "shaykekeidar/kub-demo-auth"
        $AppFolder = "$RootPath\app\auth-api"
        $DeploymentFile = "$RootPath\k8s-raw-yaml\auth\auth-deployment.yaml"
        $EnvVariable = "AUTH_VERSION"
        $DeploymentName = "auth-deployment"
    }

    "tasks" {
        $DockerRepo = "shaykekeidar/kub-demo-tasks"
        $AppFolder = "$RootPath\app\tasks-api"
        $DeploymentFile = "$RootPath\k8s-raw-yaml\tasks\tasks-deployment.yaml"
        $EnvVariable = "TASKS_VERSION"
        $DeploymentName = "tasks-deployment"
    }

    "frontend" {
        $DockerRepo = "shaykekeidar/kub-demo-frontend"
        $AppFolder = "$RootPath\app\frontend"
        $DeploymentFile = "$RootPath\k8s-raw-yaml\frontend\frontend-deployment.yaml"
        $ConfigMapFile = "$RootPath\k8s-raw-yaml\frontend\frontend-configmap.yaml"
        $EnvVariable = "FRONTEND_VERSION"
        $DeploymentName = "frontend-deployment"
    }
}

$Image = "$DockerRepo`:$Version"

Write-Host ""
Write-Host "Application : $Application"
Write-Host "Version     : $Version"
Write-Host "Image       : $Image"
Write-Host ""

Write-Host "Checking if Docker tag already exists in registry..."

if (Test-DockerTagExists -Image $Image) {
    Write-Error "Docker image tag already exists: $Image"
    Write-Host ""
    Write-Host "Update the version in:"
    Write-Host "  $VersionFile"
    Write-Host ""
    Write-Host "Example:"
    Write-Host "  $Application=$([int]$Version + 1)"
    exit 1
}

Write-Host "Tag is new. Continuing..."

Push-Location $AppFolder

docker build -t $Image .

if ($LASTEXITCODE -ne 0) {
    Pop-Location
    Write-Error "Docker build failed"
    exit 1
}

docker push $Image

if ($LASTEXITCODE -ne 0) {
    Pop-Location
    Write-Error "Docker push failed"
    exit 1
}

Pop-Location

# Update image in Deployment YAML
$content = Get-Content $DeploymentFile -Raw
$EscapedDockerRepo = [regex]::Escape($DockerRepo)
$content = $content -replace "image:\s*${EscapedDockerRepo}:\d+", "image: $Image"

# Old behavior for users/auth/tasks: version env var is inside Deployment YAML
# New behavior for frontend: version env var is inside ConfigMap YAML
if ($Application -eq "frontend") {
    Set-Content -Path $DeploymentFile -Value $content

    $configContent = Get-Content $ConfigMapFile -Raw
    $configContent = $configContent -replace "($EnvVariable\s*:\s*)`"\d+`"", "`$1`"$Version`""
    Set-Content -Path $ConfigMapFile -Value $configContent
}
else {
    $content = $content -replace "(?s)(name:\s*$EnvVariable\s*[\r\n]+\s*value:\s*)`"\d+`"", "`$1`"$Version`""
    Set-Content -Path $DeploymentFile -Value $content
}

$YamlFolder = Split-Path $DeploymentFile

kubectl apply -f $YamlFolder

if ($LASTEXITCODE -ne 0) {
    Write-Error "kubectl apply failed"
    exit 1
}

# Needed because ConfigMap env vars are loaded only when the Pod starts
if ($Application -eq "frontend") {
    kubectl rollout restart deployment $DeploymentName

    if ($LASTEXITCODE -ne 0) {
        Write-Error "kubectl rollout restart failed"
        exit 1
    }
}

Write-Host ""
Write-Host "Deployment completed successfully for $Application version $Version"
```