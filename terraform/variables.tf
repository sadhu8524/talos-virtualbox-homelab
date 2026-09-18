variable "cluster_name" {
  description = "Talos and Kubernetes cluster name."
  type        = string
  default     = "homelab"
}

variable "control_plane_name" {
  description = "VirtualBox name of the control-plane VM."
  type        = string
  default     = "talos-cp01"
}

variable "control_plane_ip" {
  description = "Host-only IPv4 address reserved for the control-plane VM."
  type        = string
  default     = "192.168.56.10"
}

variable "worker_names" {
  description = "VirtualBox names of the worker VMs."
  type        = list(string)
  default     = ["talos-worker01", "talos-worker02"]
}

variable "worker_ips" {
  description = "Host-only IPv4 addresses reserved for workers."
  type        = list(string)
  default     = ["192.168.56.11", "192.168.56.12"]

  validation {
    condition     = length(var.worker_ips) == length(var.worker_names)
    error_message = "worker_ips and worker_names must contain the same number of elements."
  }
}

variable "vm_cpus" {
  description = "Number of vCPUs assigned to each VM."
  type        = number
  default     = 2
}

variable "vm_memory_mb" {
  description = "Memory assigned to each VM in MiB."
  type        = number
  default     = 4096
}

variable "disk_size_mb" {
  description = "Virtual disk size for each VM in MiB."
  type        = number
  default     = 30720
}

variable "host_only_adapter" {
  description = "Existing or desired VirtualBox host-only adapter name on Windows."
  type        = string
  default     = "VirtualBox Host-Only Ethernet Adapter"
}

variable "host_only_gateway" {
  description = "IPv4 address assigned to the host side of the host-only adapter."
  type        = string
  default     = "192.168.56.1"
}

variable "host_only_netmask" {
  description = "Netmask used by the host-only network."
  type        = string
  default     = "255.255.255.0"
}

variable "talos_version" {
  description = "Talos release used to build the lab."
  type        = string
  default     = "v1.14.1"
}

variable "talos_iso_path" {
  description = "Optional local Talos ISO. Empty means download into the project cache."
  type        = string
  default     = ""
}

variable "install_disk" {
  description = "Talos disk device inside each VM."
  type        = string
  default     = "/dev/sda"
}

variable "auto_bootstrap" {
  description = "Run talosctl configuration and Kubernetes bootstrap during apply."
  type        = bool
  default     = true
}
