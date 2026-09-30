output "k8s_node_names" {
  description = "K3s node hostnames"
  value       = [for node in var.k8s_nodes : node.name]
}

output "k8s_node_ips" {
  description = "K3s node IP addresses"
  value       = { for node in var.k8s_nodes : node.name => node.ip }
}

output "bootstrap_server_ip" {
  description = "IP of the first K3s server used for cluster-init"
  value       = local.bootstrap_server_ip
}

output "api_vip" {
  description = "Configured virtual IP for the K3s API (apply kube-vip manifest to activate)"
  value       = var.api_vip
}

output "kubeconfig_command" {
  description = "Command to fetch kubeconfig from the bootstrap server"
  value       = "ssh ubuntu@${local.bootstrap_server_ip} 'sudo cat /etc/rancher/k3s/k3s.yaml' | sed 's/127.0.0.1/${var.api_vip != "" ? var.api_vip : local.bootstrap_server_ip}/' > kubeconfig"
}

output "cluster_health_command" {
  description = "Command to verify all nodes joined the cluster"
  value       = "kubectl --kubeconfig kubeconfig get nodes -o wide"
}
