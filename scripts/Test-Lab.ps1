[CmdletBinding()]
param(
    [string]$ControlPlaneIp = '192.168.56.10',
    [string]$GeneratedDirectory = (Join-Path (Split-Path $PSScriptRoot -Parent) 'talos/generated')
)

$ErrorActionPreference = 'Stop'
$talosConfig = Join-Path $GeneratedDirectory 'talosconfig'
$kubeconfig = Join-Path $GeneratedDirectory 'kubeconfig'

if (-not (Test-Path $talosConfig) -or -not (Test-Path $kubeconfig)) {
    throw 'Generated Talos or Kubernetes client configuration was not found.'
}

$env:TALOSCONFIG = (Resolve-Path $talosConfig).Path
& talosctl health --nodes $ControlPlaneIp
if ($LASTEXITCODE -ne 0) { throw 'Talos health check failed.' }

& kubectl --kubeconfig $kubeconfig get nodes -o wide
if ($LASTEXITCODE -ne 0) { throw 'Kubernetes node check failed.' }

& kubectl --kubeconfig $kubeconfig get pods --all-namespaces
if ($LASTEXITCODE -ne 0) { throw 'Kubernetes pod check failed.' }

