# Architecture

## Layers

| Layer | Tool | Responsibility |
|---|---|---|
| Host | Windows + VirtualBox | Hypervisor and local networking |
| Infrastructure | Terraform/OpenTofu | Desired VM lifecycle and inputs |
| Provisioning | PowerShell + VBoxManage | VM, disk, adapter, and ISO operations |
| Node OS | Talos Linux | Immutable Kubernetes node lifecycle |
| Cluster | Kubernetes | Workload orchestration |
| Client | `talosctl` + `kubectl` | Administration and verification |

Terraform deliberately uses the built-in `terraform_data` resource and
`VBoxManage` rather than depending on an unofficial VirtualBox provider. This
keeps the provider surface small and makes each hypervisor operation visible in
PowerShell.

## Networking

NIC 1 uses a VirtualBox host-only adapter. Fixed DHCP leases map stable MAC
addresses to `192.168.56.10-12`, allowing the Windows host to reach the Talos
API on TCP 50000 and the Kubernetes API on TCP 6443.

NIC 2 uses ordinary VirtualBox NAT. It supplies outbound access for image pulls
without exposing the VMs to the physical LAN.

## State and secrets

Terraform state tracks inputs and the local provisioning lifecycle. Talos PKI,
machine configuration, and kubeconfig are stored in `talos/generated/`, which
is excluded from version control. Losing that directory means losing client
credentials; rebuild the disposable lab or back it up securely.

## Idempotency boundary

The scripts tolerate an existing VM and an existing generated Talos client
configuration. Material VM changes such as CPU or disk size are best applied by
destroying and recreating the lab.

