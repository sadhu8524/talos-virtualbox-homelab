[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$required = @('VBoxManage', 'talosctl', 'kubectl')
$terraformChoices = @('terraform', 'tofu')
$failed = $false

foreach ($name in $required) {
    $command = Get-Command $name -ErrorAction SilentlyContinue
    if ($command) {
        Write-Host "[OK] $name -> $($command.Source)" -ForegroundColor Green
    }
    else {
        Write-Host "[MISSING] $name" -ForegroundColor Red
        $failed = $true
    }
}

$iac = $terraformChoices | ForEach-Object { Get-Command $_ -ErrorAction SilentlyContinue } | Select-Object -First 1
if ($iac) {
    Write-Host "[OK] Terraform-compatible CLI -> $($iac.Source)" -ForegroundColor Green
}
else {
    Write-Host '[MISSING] terraform or tofu' -ForegroundColor Red
    $failed = $true
}

if (-not [Environment]::Is64BitOperatingSystem) {
    Write-Host '[MISSING] A 64-bit operating system is required.' -ForegroundColor Red
    $failed = $true
}

if ($failed) {
    throw 'One or more prerequisites are missing.'
}

Write-Host 'All prerequisites are available.' -ForegroundColor Cyan

