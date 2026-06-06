param(
    [ValidateSet("users", "auth", "tasks", "frontend", "all")]
    [string]$Application
)

function Show-Help {
    Write-Host ""
    Write-Host "========================================"
    Write-Host " Docker Image Build Utility"
    Write-Host "========================================"
    Write-Host ""
    Write-Host "Usage:"
    Write-Host "  .\buildImage.ps1 users"
    Write-Host "  .\buildImage.ps1 auth"
    Write-Host "  .\buildImage.ps1 tasks"
    Write-Host "  .\buildImage.ps1 frontend"
    Write-Host "  .\buildImage.ps1 all"
    Write-Host ""
}

if (-not $Application) {
    Show-Help
    exit 1
}

if ($Application -eq "all") {
    foreach ($App in @("users", "auth", "tasks", "frontend")) {
        Write-Host ""
        Write-Host "========================================"
        Write-Host "Building $App"
        Write-Host "========================================"

        & $PSCommandPath $App

        if ($LASTEXITCODE -ne 0) {
            Write-Error "Build failed for $App"
            exit 1
        }
    }

    Write-Host ""
    Write-Host "All applications built successfully."
    exit 0
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

switch ($Application) {
    "users" {
        $DockerRepo = "shaykekeidar/kub-demo-users"
        $AppFolder = "$RootPath\app\users-api"
    }

    "auth" {
        $DockerRepo = "shaykekeidar/kub-demo-auth"
        $AppFolder = "$RootPath\app\auth-api"
    }

    "tasks" {
        $DockerRepo = "shaykekeidar/kub-demo-tasks"
        $AppFolder = "$RootPath\app\tasks-api"
    }

    "frontend" {
        $DockerRepo = "shaykekeidar/kub-demo-frontend"
        $AppFolder = "$RootPath\app\frontend"
    }
}

$Image = "$DockerRepo`:$Version"
$LatestImage = "$DockerRepo`:latest"

docker manifest inspect $Image *> $null

if ($LASTEXITCODE -eq 0) {

    Write-Host "Image already exists: $Image"
    Write-Host "Updating latest tag..."

    docker pull $Image

    if ($LASTEXITCODE -ne 0) {
        exit 1
    }

    docker tag $Image $LatestImage

    if ($LASTEXITCODE -ne 0) {
        exit 1
    }

    docker push $LatestImage

    if ($LASTEXITCODE -ne 0) {
        exit 1
    }

    Write-Host "Latest tag updated: $LatestImage"
    exit 0
}

Push-Location $AppFolder

docker build -t $Image -t $LatestImage .

if ($LASTEXITCODE -ne 0) {
    Pop-Location
    exit 1
}

docker push $Image

if ($LASTEXITCODE -ne 0) {
    Pop-Location
    exit 1
}

docker push $LatestImage

if ($LASTEXITCODE -ne 0) {
    Pop-Location
    exit 1
}

Pop-Location

Write-Host ""
Write-Host "Image built and pushed: $Image"
Write-Host "Latest tag updated: $LatestImage"
