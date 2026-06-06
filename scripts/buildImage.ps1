param(
    [ValidateSet("users", "auth", "tasks", "frontend")]
    [string]$Application
)

$RootPath = "D:\Kubernetes\kub-network-01-starting-setup"
$VersionFile = "$RootPath\app\application-versions.txt"

$Versions = @{}
Get-Content $VersionFile | ForEach-Object {
    if ($_ -match "^\s*([^=]+)\s*=\s*(\d+)\s*$") {
        $Versions[$matches[1].Trim()] = $matches[2].Trim()
    }
}

$Version = $Versions[$Application]

switch ($Application) {
    "users"    { $DockerRepo = "shaykekeidar/kub-demo-users";    $AppFolder = "$RootPath\app\users-api" }
    "auth"     { $DockerRepo = "shaykekeidar/kub-demo-auth";     $AppFolder = "$RootPath\app\auth-api" }
    "tasks"    { $DockerRepo = "shaykekeidar/kub-demo-tasks";    $AppFolder = "$RootPath\app\tasks-api" }
    "frontend" { $DockerRepo = "shaykekeidar/kub-demo-frontend"; $AppFolder = "$RootPath\app\frontend" }
}

$Image = "$DockerRepo`:$Version"

docker manifest inspect $Image *> $null
if ($LASTEXITCODE -eq 0) {
    Write-Host "Image already exists: $Image"
    exit 0
}

Push-Location $AppFolder

docker build -t $Image .
if ($LASTEXITCODE -ne 0) { exit 1 }

docker push $Image
if ($LASTEXITCODE -ne 0) { exit 1 }

Pop-Location

Write-Host "Image built and pushed: $Image"