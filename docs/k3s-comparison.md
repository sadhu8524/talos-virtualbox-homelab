# Optional k3s comparison lab

Talos and k3s solve different parts of the Kubernetes learning problem and
should be built as separate labs.

| Talos lab | k3s lab |
|---|---|
| Talos Linux | Ubuntu or another conventional Linux distribution |
| Immutable and API-managed | SSH, packages, and systemd |
| Standard Kubernetes components | Lightweight Kubernetes distribution |
| Machine configuration YAML | cloud-init and/or Ansible |
| `talosctl` operations | shell and Ansible operations |

A complementary k3s repository can reuse the VirtualBox VM pattern, replace the
Talos ISO with an Ubuntu cloud image, and run an Ansible playbook that:

1. installs the first k3s server;
2. reads the join token securely;
3. joins two k3s agents;
4. retrieves kubeconfig;
5. verifies the cluster.

Keeping the two labs separate makes their operational trade-offs clear and
avoids attempting to install k3s on Talos, which is purpose-built to manage its
own Kubernetes distribution.

