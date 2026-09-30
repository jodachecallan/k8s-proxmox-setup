variable "proxmox_endpoint" {
  description = "Proxmox API endpoint, e.g. https://192.168.2.10:8006"
  type        = string
}

variable "proxmox_token_id" {
  description = "Proxmox API token ID, e.g. terraform@pam!k8s"
  type        = string
  sensitive   = true
}

variable "proxmox_token_secret" {
  description = "Proxmox API token secret"
  type        = string
  sensitive   = true
}

variable "proxmox_insecure" {
  description = "Skip TLS verification for the Proxmox API"
  type        = bool
  default     = true
}

variable "proxmox_ssh_username" {
  description = "SSH username for Proxmox host access (used by provider)"
  type        = string
  default     = "root"
}

variable "proxmox_nodes" {
  description = "Proxmox node names, one per K8s VM"
  type        = list(string)
}

variable "k8s_nodes" {
  description = "K3s server VM definitions (datastore_id is per-node; must exist on that Proxmox node)"
  type = list(object({
    name         = string
    proxmox_node = string
    ip           = string
    vm_id        = number
    datastore_id = string
    cpu_cores    = optional(number)
    memory_mb    = optional(number)
  }))
}

variable "network_gateway" {
  description = "Default gateway for K8s nodes"
  type        = string
}

variable "network_cidr_prefix" {
  description = "CIDR prefix length for node IPs"
  type        = number
  default     = 24
}

variable "network_bridge" {
  description = "Proxmox network bridge for VM NICs"
  type        = string
  default     = "vmbr0"
}

variable "snippets_datastore_id" {
  description = "Unused legacy var (snippets no longer required; kept for tfvars compatibility)"
  type        = string
  default     = "local"
}

variable "image_datastore_id" {
  description = "Proxmox datastore that accepts content type import (typically local)"
  type        = string
  default     = "local"
}

variable "dns_servers" {
  description = "DNS servers for K8s node cloud-init"
  type        = list(string)
  default     = ["192.168.2.254", "1.1.1.1"]
}

variable "ubuntu_cloud_image_url" {
  description = "Ubuntu cloud image URL to import"
  type        = string
  default     = "https://cloud-images.ubuntu.com/releases/24.04/release/ubuntu-24.04-server-cloudimg-amd64.img"
}

variable "ssh_public_key" {
  description = "SSH public key for the ubuntu user on K8s nodes"
  type        = string
}

variable "ssh_private_key_path" {
  description = "Path to SSH private key used to bootstrap K3s on the VMs"
  type        = string
  default     = "~/.ssh/id_ed25519"
}

variable "vm_cpu_cores" {
  description = "vCPU count per K8s node"
  type        = number
  default     = 4
}

variable "vm_memory_mb" {
  description = "Memory in MiB per K8s node"
  type        = number
  default     = 8192
}

variable "vm_disk_gb" {
  description = "Root disk size in GiB per K8s node"
  type        = number
  default     = 40
}

variable "api_vip" {
  description = "Virtual IP for the K3s API server"
  type        = string
}

variable "k3s_token" {
  description = "Pre-shared K3s cluster token used by all server nodes"
  type        = string
  sensitive   = true
}

variable "k3s_version" {
  description = "K3s version channel or explicit version"
  type        = string
  default     = "latest"
}
