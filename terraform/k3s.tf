resource "null_resource" "k3s_bootstrap" {
  depends_on = [proxmox_virtual_environment_vm.k8s_node]

  triggers = {
    ip          = local.bootstrap_server_ip
    k3s_version = var.k3s_version
    k3s_token   = var.k3s_token
    tls_sans    = local.tls_sans_flags
  }

  connection {
    type        = "ssh"
    host        = local.bootstrap_server_ip
    user        = "ubuntu"
    private_key = local.ssh_private_key
    timeout     = "15m"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cloud-init status --wait",
      "while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do echo waiting-for-apt; sleep 5; done",
      "sudo apt-get update -y",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y curl jq qemu-guest-agent",
      "sudo systemctl enable --now qemu-guest-agent",
      "sudo swapoff -a",
      "sudo sed -i '/ swap / s/^/#/' /etc/fstab || true",
      "echo net.ipv4.ip_forward=1 | sudo tee /etc/sysctl.d/99-k8s.conf",
      "sudo sysctl --system",
      "curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC=\"server --cluster-init --token ${var.k3s_token} --disable traefik --disable servicelb ${local.tls_sans_flags}\" sh -",
      "sudo k3s kubectl get nodes",
    ]
  }
}

resource "null_resource" "k3s_join" {
  for_each = local.join_nodes

  depends_on = [null_resource.k3s_bootstrap]

  triggers = {
    ip          = each.value.ip
    k3s_version = var.k3s_version
    k3s_token   = var.k3s_token
    server      = local.bootstrap_server_ip
    tls_sans    = local.tls_sans_flags
  }

  connection {
    type        = "ssh"
    host        = each.value.ip
    user        = "ubuntu"
    private_key = local.ssh_private_key
    timeout     = "15m"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo cloud-init status --wait",
      "while sudo fuser /var/lib/dpkg/lock-frontend >/dev/null 2>&1; do echo waiting-for-apt; sleep 5; done",
      "sudo apt-get update -y",
      "sudo DEBIAN_FRONTEND=noninteractive apt-get install -y curl jq qemu-guest-agent",
      "sudo systemctl enable --now qemu-guest-agent",
      "sudo swapoff -a",
      "sudo sed -i '/ swap / s/^/#/' /etc/fstab || true",
      "echo net.ipv4.ip_forward=1 | sudo tee /etc/sysctl.d/99-k8s.conf",
      "sudo sysctl --system",
      "curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC=\"server --server https://${local.bootstrap_server_ip}:6443 --token ${var.k3s_token} --disable traefik --disable servicelb ${local.tls_sans_flags}\" sh -",
      "sudo k3s kubectl get nodes",
    ]
  }
}
