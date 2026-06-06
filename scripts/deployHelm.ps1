param(
    [ValidateSet("users", "auth", "tasks", "frontend")]
    [string]$Application,

    [ValidateSet("dev", "test")]
    [string]$Environment,

    [string]$Version
)

$RootPath = "D:\Kubernetes\kub-network-01-starting-setup"
$HelmChartPath = "$RootPath\helm\task-generator"
$ValuesFile = "$HelmChartPath\values-$Environment.yaml"

$Namespace = "task-generator-$Environment"
$ReleaseName = "task-generator-$Environment"

$SetArgs = @()

switch ($Application) {
    "frontend" {
        $SetArgs += "--set"
        $SetArgs += "frontend.image.tag=$Version"
        $SetArgs += "--set"
        $SetArgs += "frontend.config.FRONTEND_VERSION=$Version"
    }

    "users" {
        $SetArgs += "--set"
        $SetArgs += "users.image.tag=$Version"
    }

    "auth" {
        $SetArgs += "--set"
        $SetArgs += "auth.image.tag=$Version"
    }

    "tasks" {
        $SetArgs += "--set"
        $SetArgs += "tasks.image.tag=$Version"
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