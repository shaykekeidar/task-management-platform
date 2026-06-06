param(
    [ValidateSet("users", "auth", "tasks", "frontend", "all")]
    [string]$Application,

    [ValidateSet("dev", "test")]
    [string]$Environment
)

function Show-Help {
    Write-Host ""
    Write-Host "========================================"
    Write-Host " Helm Deployment Utility"
    Write-Host "========================================"
    Write-Host ""
    Write-Host "Usage:"
    Write-Host "  .\deployHelm.ps1 users dev"
    Write-Host "  .\deployHelm.ps1 auth dev"
    Write-Host "  .\deployHelm.ps1 tasks test"
    Write-Host "  .\deployHelm.ps1 frontend test"
    Write-Host "  .\deployHelm.ps1 all dev"
    Write-Host "  .\deployHelm.ps1 all test"

    Write-Host ""
}

if (-not $Application -or -not $Environment) {
    Show-Help
    exit 1
}

$RootPath = "D:\Kubernetes\kub-network-01-starting-setup"
$VersionFile = "$RootPath\app\application-versions.txt"

$HelmChartPath = "$RootPath\helm\task-generator"
$ValuesFile = "$HelmChartPath\values-$Environment.yaml"

$Namespace = "task-generator-$Environment"
$ReleaseName = "task-generator-$Environment"

$Versions = @{}

Get-Content $VersionFile | ForEach-Object {
    if ($_ -match "^\s*([^=]+)\s*=\s*(\d+)\s*$") {
        $Versions[$matches[1].Trim()] = $matches[2].Trim()
    }
}

if ($Application -eq "all") {
    foreach ($App in @("users", "auth", "tasks", "frontend")) {
        Write-Host ""
        Write-Host "Deploying $App to $Environment"

        & $PSCommandPath $App $Environment

        if ($LASTEXITCODE -ne 0) {
            Write-Error "Deployment failed for $App"
            exit 1
        }
    }

    Write-Host ""
    Write-Host "All applications deployed to $Environment successfully."
    exit 0
}

$Version = $Versions[$Application]

if (-not $Version) {
    Write-Error "Version for '$Application' not found in $VersionFile"
    exit 1
}

$FrontendVersion = $Versions["frontend"]
$UsersVersion    = $Versions["users"]
$AuthVersion     = $Versions["auth"]
$TasksVersion    = $Versions["tasks"]

$SetArgs = @(
    "--set", "frontend.image.tag=$FrontendVersion",
    "--set", "frontend.config.FRONTEND_VERSION=$FrontendVersion",

    "--set", "users.image.tag=$UsersVersion",
    "--set", "users.config.USERS_VERSION=$UsersVersion",

    "--set", "auth.image.tag=$AuthVersion",
    "--set", "auth.config.AUTH_VERSION=$AuthVersion",

    "--set", "tasks.image.tag=$TasksVersion",
    "--set", "tasks.config.TASKS_VERSION=$TasksVersion"
)

switch ($Application) {
    "frontend" {
        $SetArgs += "--set"; $SetArgs += "frontend.image.tag=$Version"
        $SetArgs += "--set"; $SetArgs += "frontend.config.FRONTEND_VERSION=$Version"
    }

    "users" {
        $SetArgs += "--set"; $SetArgs += "users.image.tag=$Version"
        $SetArgs += "--set"; $SetArgs += "users.config.USERS_VERSION=$Version"
    }

    "auth" {
        $SetArgs += "--set"; $SetArgs += "auth.image.tag=$Version"
        $SetArgs += "--set"; $SetArgs += "auth.config.AUTH_VERSION=$Version"
    }

    "tasks" {
        $SetArgs += "--set"; $SetArgs += "tasks.image.tag=$Version"
        $SetArgs += "--set"; $SetArgs += "tasks.config.TASKS_VERSION=$Version"
    }
}

helm upgrade --install $ReleaseName $HelmChartPath `
    -f $ValuesFile `
    @SetArgs `
    -n $Namespace `
    --create-namespace

if ($LASTEXITCODE -ne 0) {
    Write-Error "Helm deployment failed"
    exit 1
}

Write-Host "Helm deployment completed: $Application $Environment version $Version"