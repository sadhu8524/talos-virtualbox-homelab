[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$NodesJson,
    [int]$CpuCount = 2,
    [int]$MemoryMb = 4096,
    [int]$DiskSizeMb = 30720,
    [string]$HostOnlyAdapter = 'VirtualBox Host-Only Ethernet Adapter',
    [string]$HostOnlyGateway = '192.168.56.1',
    [string]$HostOnlyNetmask = '255.255.255.0',
    [string]$TalosVersion = 'v1.14.1',
    [string]$TalosIsoPath = ''
)

. "$PSScriptRoot/Common.ps1"

$nodes = @($NodesJson | ConvertFrom-Json)
if ($nodes.Count -lt 1) {
    throw 'At least one node must be supplied.'
}

if ([string]::IsNullOrWhiteSpace($TalosIsoPath)) {
    $cacheDirectory = Join-Path (Split-Path $PSScriptRoot -Parent) '.cache'
    New-Item -ItemType Directory -Path $cacheDirectory -Force | Out-Null
    $TalosIsoPath = Join-Path $cacheDirectory "talos-$TalosVersion-metal-amd64.iso"
    if (-not (Test-Path $TalosIsoPath)) {
        $isoUrl = "https://github.com/siderolabs/talos/releases/download/$TalosVersion/metal-amd64.iso"
        Write-Host "Downloading Talos $TalosVersion ISO..."
        Invoke-WebRequest -Uri $isoUrl -OutFile $TalosIsoPath
    }
}

$TalosIsoPath = (Resolve-Path $TalosIsoPath).Path

$hostOnlyList = (& (Get-RequiredCommand 'VBoxManage') list hostonlyifs) -join "`n"
if ($hostOnlyList -notmatch ("(?m)^Name:\s+" + [regex]::Escape($HostOnlyAdapter) + "\s*$")) {
    Write-Host "Creating host-only adapter '$HostOnlyAdapter'..."
    $createOutput = (& (Get-RequiredCommand 'VBoxManage') hostonlyif create) -join "`n"
    if ($createOutput -match "Interface '([^']+)' was successfully created") {
        $HostOnlyAdapter = $Matches[1]
        Write-Host "Using newly created adapter '$HostOnlyAdapter'."
    }
    else {
        throw 'VirtualBox created an adapter but its name could not be determined.'
    }
}

Invoke-VBoxManage -Arguments @('hostonlyif', 'ipconfig', $HostOnlyAdapter, "--ip=$HostOnlyGateway", "--netmask=$HostOnlyNetmask")

# Keep addresses stable by reserving each MAC in the host-only DHCP server.
Invoke-VBoxManage -Arguments @('dhcpserver', 'remove', "--interface=$HostOnlyAdapter") -IgnoreExitCode
$networkOctets = $HostOnlyGateway.Split('.')
if ($networkOctets.Count -ne 4) {
    throw "HostOnlyGateway '$HostOnlyGateway' is not a valid IPv4 address."
}
$networkPrefix = ($networkOctets[0..2] -join '.')

Invoke-VBoxManage -Arguments @(
    'dhcpserver', 'add', "--interface=$HostOnlyAdapter",
    "--server-ip=$HostOnlyGateway", "--netmask=$HostOnlyNetmask",
    "--lower-ip=$networkPrefix.10", "--upper-ip=$networkPrefix.99", '--enable'
)

$vmRoot = Join-Path (Split-Path $PSScriptRoot -Parent) '.vms'
New-Item -ItemType Directory -Path $vmRoot -Force | Out-Null

for ($index = 0; $index -lt $nodes.Count; $index++) {
    $node = $nodes[$index]
    $name = [string]$node.name
    $ip = [string]$node.ip
    $mac = '080027{0:X6}' -f (0xA00000 + $index + 1)
    $vmDirectory = Join-Path $vmRoot $name
    $diskPath = Join-Path $vmDirectory "$name.vdi"

    $existingVms = (& (Get-RequiredCommand 'VBoxManage') list vms) -join "`n"
    if ($existingVms -match ('"' + [regex]::Escape($name) + '"')) {
        Write-Host "VM '$name' already exists; leaving it unchanged."
        continue
    }

    New-Item -ItemType Directory -Path $vmDirectory -Force | Out-Null
    Invoke-VBoxManage -Arguments @('createvm', "--name=$name", '--ostype=Linux_64', "--basefolder=$vmRoot", '--register')
    Invoke-VBoxManage -Arguments @(
        'modifyvm', $name, "--cpus=$CpuCount", "--memory=$MemoryMb",
        '--ioapic=on', '--firmware=efi', '--graphicscontroller=vmsvga',
        '--boot1=disk', '--boot2=dvd', '--boot3=none', '--boot4=none',
        '--nic1=hostonly', "--host-only-adapter1=$HostOnlyAdapter", "--mac-address1=$mac",
        '--nic2=nat', '--nictype1=virtio', '--nictype2=virtio',
        '--uart1=0x3F8', '--uartmode1=disconnected'
    )
    Invoke-VBoxManage -Arguments @('createmedium', 'disk', "--filename=$diskPath", "--size=$DiskSizeMb", '--format=VDI')
    Invoke-VBoxManage -Arguments @('storagectl', $name, '--name=SATA', '--add=sata', '--controller=IntelAhci')
    Invoke-VBoxManage -Arguments @('storageattach', $name, '--storagectl=SATA', '--port=0', '--device=0', '--type=hdd', "--medium=$diskPath")
    Invoke-VBoxManage -Arguments @('storagectl', $name, '--name=IDE', '--add=ide', '--controller=PIIX4')
    Invoke-VBoxManage -Arguments @('storageattach', $name, '--storagectl=IDE', '--port=0', '--device=0', '--type=dvddrive', "--medium=$TalosIsoPath")
    Invoke-VBoxManage -Arguments @('dhcpserver', 'modify', "--interface=$HostOnlyAdapter", "--mac-address=$mac", "--fixed-address=$ip")
    Invoke-VBoxManage -Arguments @('startvm', $name, '--type=headless')
}

Write-Host 'VirtualBox VMs are running.' -ForegroundColor Green
