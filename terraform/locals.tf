locals {
  repository_root = abspath("${path.module}/..")
  scripts_dir     = "${local.repository_root}/scripts"

  nodes = concat(
    [{
      name = var.control_plane_name
      ip   = var.control_plane_ip
      role = "controlplane"
    }],
    [for index, name in var.worker_names : {
      name = name
      ip   = var.worker_ips[index]
      role = "worker"
    }]
  )

  node_spec_json = jsonencode(local.nodes)
}

