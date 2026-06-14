param(
    [ValidateSet("users", "auth", "tasks", "frontend")]
    [string]$Application,

    [ValidateSet("dev", "test")]
    [string]$Environment = "dev"
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

if (-not $Version) {
    Write-Error "Version for '$Application' not found"
    exit 1
}

& "$RootPath\scripts\buildImage.ps1" $Application
if ($LASTEXITCODE -ne 0) { exit 1 }

Write-Host "Helm is disabled"
#& "$RootPath\scripts\deployHelm.ps1" $Application $Environment $Version
#if ($LASTEXITCODE -ne 0) { exit 1 }

Write-Host "Release completed: $Application $Environment version $Version"