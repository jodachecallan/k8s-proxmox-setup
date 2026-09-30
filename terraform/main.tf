provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = "${var.proxmox_token_id}=${var.proxmox_token_secret}"
  insecure  = var.proxmox_insecure
}

# Cloud image must already exist on each node's local import store:
#   local:import/ubuntu-24.04-server-cloudimg-amd64.qcow2
# Download once per node (as root) if missing:
#   pvesm download local --content import --filename ubuntu-24.04-server-cloudimg-amd64.qcow2 \
#     --url https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.img
