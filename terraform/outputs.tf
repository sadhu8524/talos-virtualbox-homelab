output "control_plane_endpoint" {
  description = "Kubernetes API endpoint."
  value       = "https://${var.control_plane_ip}:6443"
}

output "node_addresses" {
  description = "Management addresses assigned to all Talos VMs."
  value       = { for node in local.nodes : node.name => node.ip }
}

output "talosconfig_path" {
  description = "Generated talosctl client configuration."
  value       = "${local.repository_root}/talos/generated/talosconfig"
}

output "kubeconfig_path" {
  description = "Generated Kubernetes client configuration."
  value       = "${local.repository_root}/talos/generated/kubeconfig"
}

