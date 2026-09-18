[CmdletBinding()]
param([Parameter(Mandatory)][string]$NodesJson)

. "$PSScriptRoot/Common.ps1"
$nodes = @($NodesJson | ConvertFrom-Json)
$registered = (& (Get-RequiredCommand 'VBoxManage') list vms) -join "`n"

foreach ($node in $nodes) {
    $name = [string]$node.name
    if ($registered -notmatch ('"' + [regex]::Escape($name) + '"')) {
        continue
    }

    $running = (& (Get-RequiredCommand 'VBoxManage') list runningvms) -join "`n"
    if ($running -match ('"' + [regex]::Escape($name) + '"')) {
        Invoke-VBoxManage -Arguments @('controlvm', $name, 'poweroff') -IgnoreExitCode
    }

    Invoke-VBoxManage -Arguments @('unregistervm', $name, '--delete')
    Write-Host "Removed VM '$name'."
}

