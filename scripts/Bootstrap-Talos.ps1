[CmdletBinding()]
param(
    [string]$ClusterName = 'homelab',
    [string]$ControlPlaneName = 'talos-cp01',
    [Parameter(Mandatory)][string]$ControlPlaneIp,
    [string[]]$WorkerNames = @('talos-worker01', 'talos-worker02'),
    [string[]]$WorkerIps = @(),
    [string]$InstallDisk = '/dev/sda',
    [string]$OutputDirectory = (Join-Path (Split-Path $PSScriptRoot -Parent) 'talos/generated')
)

. "$PSScriptRoot/Common.ps1"
Get-RequiredCommand -Name 'talosctl' | Out-Null
Get-RequiredCommand -Name 'kubectl' | Out-Null

if ($WorkerNames.Count -ne $WorkerIps.Count) {
    throw 'WorkerNames and WorkerIps must contain the same number of elements.'
}

New-Item -ItemType Directory -Path $OutputDirectory -Force | Out-Null
$OutputDirectory = (Resolve-Path $OutputDirectory).Path
$endpoint = "https://${ControlPlaneIp}:6443"

Write-Host 'Waiting for Talos maintenance API...'
@($ControlPlaneIp) + $WorkerIps | ForEach-Object {
    Wait-TcpPort -ComputerName $_ -Port 50000 -TimeoutSeconds 600
}

$controlPlaneConfig = Join-Path $OutputDirectory 'controlplane.yaml'
$workerConfig = Join-Path $OutputDirectory 'worker.yaml'
$talosConfig = Join-Path $OutputDirectory 'talosconfig'

if (-not (Test-Path $talosConfig)) {
    & talosctl gen config $ClusterName $endpoint --output-dir $OutputDirectory --install-disk $InstallDisk
    if ($LASTEXITCODE -ne 0) {
        throw 'talosctl gen config failed.'
    }
}

function Set-TalosNodeConfig {
    param(
        [Parameter(Mandatory)][string]$Address,
        [Parameter(Mandatory)][string]$NodeName,
        [Parameter(Mandatory)][string]$BaseConfig
    )

    $patchPath = Join-Path $OutputDirectory "$NodeName.patch.yaml"
    @"
machine:
  network:
    hostname: $NodeName
"@ | Set-Content -Path $patchPath -Encoding utf8

    & talosctl apply-config --insecure --nodes $Address --file $BaseConfig --config-patch "@$patchPath"
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to apply Talos configuration to $NodeName ($Address)."
    }
}

Set-TalosNodeConfig -Address $ControlPlaneIp -NodeName $ControlPlaneName -BaseConfig $controlPlaneConfig
for ($index = 0; $index -lt $WorkerIps.Count; $index++) {
    Set-TalosNodeConfig -Address $WorkerIps[$index] -NodeName $WorkerNames[$index] -BaseConfig $workerConfig
}

$env:TALOSCONFIG = $talosConfig
Write-Host 'Waiting for the configured control plane...'
Wait-TcpPort -ComputerName $ControlPlaneIp -Port 50000 -TimeoutSeconds 600

& talosctl config endpoint $ControlPlaneIp
& talosctl config node $ControlPlaneIp

$bootstrapMarker = Join-Path $OutputDirectory '.bootstrapped'
if (-not (Test-Path $bootstrapMarker)) {
    & talosctl bootstrap --nodes $ControlPlaneIp
    if ($LASTEXITCODE -ne 0) {
        throw 'Talos etcd bootstrap failed.'
    }
    New-Item -ItemType File -Path $bootstrapMarker -Force | Out-Null
}

$kubeconfigPath = Join-Path $OutputDirectory 'kubeconfig'
& talosctl kubeconfig $kubeconfigPath --nodes $ControlPlaneIp --force
if ($LASTEXITCODE -ne 0) {
    throw 'Failed to retrieve kubeconfig.'
}

Write-Host 'Waiting for Kubernetes API and nodes...'
$deadline = (Get-Date).AddMinutes(15)
do {
    & kubectl --kubeconfig $kubeconfigPath get nodes 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "Cluster '$ClusterName' is ready." -ForegroundColor Green
        exit 0
    }
    Start-Sleep -Seconds 10
} while ((Get-Date) -lt $deadline)

throw 'Timed out waiting for Kubernetes nodes.'
