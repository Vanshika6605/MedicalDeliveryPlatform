[CmdletBinding()]
param(
    [string]$Minikube = 'minikube',
    [string]$BrowserOrigin = 'http://127.0.0.1:8094',
    [switch]$SkipBuild,
    [switch]$UseExistingCluster
)

$ErrorActionPreference = 'Stop'
$profile = 'mediflow-a2'
$namespace = 'mediflow-a2'
$images = @{ web = 'mediflow-web:k8s-1.0'; api = 'mediflow-api:k8s-1.0' }

function Invoke-Native([string]$Executable, [string[]]$Arguments) {
    & $Executable @Arguments
    if ($LASTEXITCODE -ne 0) { throw "$Executable $($Arguments[0]) exited with code $LASTEXITCODE." }
}

function New-HexSecret([int]$Length) {
    $generator = [System.Security.Cryptography.RandomNumberGenerator]::Create()
    try {
        $bytes = New-Object byte[] $Length
        $generator.GetBytes($bytes)
        return [BitConverter]::ToString($bytes).Replace('-', '').ToLowerInvariant()
    } finally {
        $generator.Dispose()
    }
}

Push-Location $PSScriptRoot
try {
    if (-not $UseExistingCluster) {
        Invoke-Native $Minikube @('start', '--driver=docker', "--profile=$profile", '--cpus=2', '--memory=2600mb')
    }
    $cluster = @('--context', $profile)
    $target = $cluster + @('--namespace', $namespace)

    foreach ($service in @('web', 'api')) {
        if (-not $SkipBuild) {
            Invoke-Native 'docker' @('build', '--target', $service, '--tag', $images[$service], '.')
        }
        if (-not $UseExistingCluster) {
            Invoke-Native $Minikube @('--profile', $profile, 'image', 'load', $images[$service], '--overwrite=true')
        }
    }

    @{
        apiVersion = 'v1'; kind = 'Namespace'; metadata = @{ name = $namespace }
    } | ConvertTo-Json -Compress | kubectl @cluster apply -f -
    if ($LASTEXITCODE -ne 0) { throw 'Could not apply the demo namespace.' }

    $secret = Invoke-Native 'kubectl' ($target + @('get', 'secret', 'mediflow-credentials', '--ignore-not-found', '-o', 'name'))
    if (-not $secret) {
        @{
            apiVersion = 'v1'; kind = 'Secret'; metadata = @{ name = 'mediflow-credentials' }; type = 'Opaque'
            stringData = @{ 'postgres-password' = New-HexSecret 24; 'jwt-secret' = New-HexSecret 32 }
        } | ConvertTo-Json -Depth 4 -Compress | kubectl @target create -f -
        if ($LASTEXITCODE -ne 0) { throw 'Could not create the demo credentials.' }
    }

    @{
        apiVersion = 'v1'; kind = 'ConfigMap'; metadata = @{ name = 'mediflow-demo-origin' }
        data = @{ url = $BrowserOrigin }
    } | ConvertTo-Json -Depth 4 -Compress | kubectl @target apply -f -
    if ($LASTEXITCODE -ne 0) { throw 'Could not apply the browser origin.' }

    Invoke-Native 'kubectl' ($target + @('apply', '-k', 'k8s'))
    foreach ($workload in @('statefulset/mediflow-db', 'deployment/mediflow-api', 'deployment/mediflow-web')) {
        Invoke-Native 'kubectl' ($target + @('rollout', 'status', $workload, '--timeout=300s'))
    }
    Invoke-Native 'kubectl' ($target + @('get', 'deployments,pods,services'))
} finally {
    Pop-Location
}
