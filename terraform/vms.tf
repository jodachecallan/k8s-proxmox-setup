resource "proxmox_virtual_environment_vm" "k8s_node" {
  for_each = { for idx, node in var.k8s_nodes : node.name => merge(node, { index = idx }) }

  name        = each.value.name
  node_name   = each.value.proxmox_node
  vm_id       = each.value.vm_id
  description = "K3s HA server node managed by OpenTofu"
  tags        = ["k3s", "terraform"]

  # Guest agent is installed during K3s bootstrap; keep disabled so create does not wait
  agent {
    enabled = false
  }
  stop_on_destroy = true

  cpu {
    cores = coalesce(each.value.cpu_cores, var.vm_cpu_cores)
    type  = "host"
  }

  memory {
    dedicated = coalesce(each.value.memory_mb, var.vm_memory_mb)
  }

  disk {
    datastore_id = each.value.datastore_id
    import_from  = "${var.image_datastore_id}:import/ubuntu-24.04-server-cloudimg-amd64.qcow2"
    interface    = "scsi0"
    size         = var.vm_disk_gb
    iothread     = false
    discard      = "on"
  }

  network_device {
    bridge = var.network_bridge
    model  = "virtio"
  }

  initialization {
    datastore_id = each.value.datastore_id

    ip_config {
      ipv4 {
        address = "${each.value.ip}/${var.network_cidr_prefix}"
        gateway = var.network_gateway
      }
    }

    dns {
      servers = var.dns_servers
    }

    user_account {
      username = "ubuntu"
      keys     = [trimspace(var.ssh_public_key)]
    }
  }

  operating_system {
    type = "l26"
  }

  startup {
    order = each.value.index + 1
  }
}
