resource "terraform_data" "virtualbox_lab" {
  input = {
    cluster_name      = var.cluster_name
    nodes_json        = local.node_spec_json
    vm_cpus           = var.vm_cpus
    vm_memory_mb      = var.vm_memory_mb
    disk_size_mb      = var.disk_size_mb
    host_only_adapter = var.host_only_adapter
    host_only_gateway = var.host_only_gateway
    host_only_netmask = var.host_only_netmask
    talos_version     = var.talos_version
    talos_iso_path    = var.talos_iso_path
    install_disk      = var.install_disk
    auto_bootstrap    = var.auto_bootstrap
    repository_root   = local.repository_root
  }

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command"]
    command     = <<-EOT
      & '${local.scripts_dir}/New-VirtualBoxLab.ps1' -NodesJson '${replace(local.node_spec_json, "'", "''")}' -CpuCount ${var.vm_cpus} -MemoryMb ${var.vm_memory_mb} -DiskSizeMb ${var.disk_size_mb} -HostOnlyAdapter '${replace(var.host_only_adapter, "'", "''")}' -HostOnlyGateway '${var.host_only_gateway}' -HostOnlyNetmask '${var.host_only_netmask}' -TalosVersion '${var.talos_version}' -TalosIsoPath '${replace(var.talos_iso_path, "'", "''")}'
      if ('${var.auto_bootstrap}' -eq 'true') {
        & '${local.scripts_dir}/Bootstrap-Talos.ps1' -ClusterName '${replace(var.cluster_name, "'", "''")}' -ControlPlaneName '${replace(var.control_plane_name, "'", "''")}' -ControlPlaneIp '${var.control_plane_ip}' -WorkerNames @(${join(",", [for name in var.worker_names : "'${replace(name, "'", "''")}'"])}) -WorkerIps @(${join(",", [for ip in var.worker_ips : "'${ip}'"])}) -InstallDisk '${var.install_disk}' -OutputDirectory '${local.repository_root}/talos/generated'
      }
    EOT
  }

  provisioner "local-exec" {
    when        = destroy
    interpreter = ["PowerShell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command"]
    command     = "& '${self.input.repository_root}/scripts/Remove-VirtualBoxLab.ps1' -NodesJson '${replace(self.input.nodes_json, "'", "''")}'"
  }
}
