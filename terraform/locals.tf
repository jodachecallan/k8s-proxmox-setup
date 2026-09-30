locals {
  bootstrap_server_ip = var.k8s_nodes[0].ip
  join_nodes          = { for idx, node in var.k8s_nodes : node.name => node if idx > 0 }

  tls_sans = distinct(concat(
    [var.api_vip, local.bootstrap_server_ip],
    [for node in var.k8s_nodes : node.ip]
  ))

  tls_sans_flags = join(" ", [for san in local.tls_sans : "--tls-san ${san}"])

  # Download the cloud image once per Proxmox node (storage is not shared)
  image_nodes = toset([for node in var.k8s_nodes : node.proxmox_node])

  ssh_private_key = file(pathexpand(var.ssh_private_key_path))
}
