# K3s on 3-Node Proxmox Cluster

Automated K3s HA cluster on three Proxmox VMs. Each VM runs as both control plane and worker (embedded etcd quorum). OpenTofu provisions the VMs; cloud-init bootstraps K3s.

## Architecture

```
Proxmox (3 physical nodes)
├── k8s-01 @ pve1  (K3s server + workloads)
├── k8s-02 @ pve2  (K3s server + workloads)
└── k8s-03 @ pve3  (K3s server + workloads)

API VIP: 192.168.2.50 (kube-vip)
```

## Prerequisites

- Proxmox VE cluster with 3 nodes
- Proxmox API token with VM permissions
- Snippets enabled on a datastore (typically `local`)
- [OpenTofu](https://opentofu.org/) or Terraform >= 1.5
- `kubectl` and `helm` on your workstation
- SSH key for the `ubuntu` user on VMs

### Create a Proxmox API token

In the Proxmox UI: **Datacenter → Permissions → API Tokens → Add**

Grant the token permission to create/manage VMs on the target nodes and datastores.

## Quick start

### 1. Configure variables

```bash
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Edit terraform/terraform.tfvars with your Proxmox details, IPs, and k3s_token
```

Generate a cluster token:

```bash
openssl rand -hex 32
```

Set that value as `k3s_token` in `terraform.tfvars`.

### 2. Provision VMs

```bash
cd terraform
tofu init
tofu plan
tofu apply
```

Nodes boot in order (`k8s-01` first, then `k8s-02` and `k8s-03` join automatically).

### 3. Fetch kubeconfig

```bash
ssh ubuntu@192.168.2.41 'sudo cat /etc/rancher/k3s/k3s.yaml' \
  | sed 's/127.0.0.1/192.168.2.41/' > ../kubeconfig

export KUBECONFIG=$(pwd)/../kubeconfig
kubectl get nodes
```

After kube-vip is deployed (step 4), update the server URL to `https://192.168.2.50:6443`.

### 4. Install cluster add-ons

Apply in this order:

```bash
# kube-vip for HA API endpoint
kubectl apply -f ../cluster/kube-vip/rbac.yaml
kubectl apply -f ../cluster/kube-vip/daemonset.yaml

# Traefik ingress
helm repo add traefik https://traefik.github.io/charts
helm repo update
helm install traefik traefik/traefik \
  -n traefik --create-namespace \
  -f ../cluster/traefik/helm-values.yaml

# cert-manager
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager \
  -n cert-manager --create-namespace \
  --set crds.enabled=true

kubectl apply -f ../cluster/letsencrypt-issuer.yaml
```

See [docs/manual-steps.md](docs/manual-steps.md) for kubeconfig details, DNS, and troubleshooting.

## Repository layout

```
├── terraform/           OpenTofu: Proxmox VMs + K3s bootstrap
├── cluster/             Cluster-level add-ons (Traefik, cert-manager, kube-vip)
└── docs/                Additional operational notes
```

## Networking

| Item | Default |
|---|---|
| LAN subnet | `192.168.2.0/24` |
| Node IPs | `192.168.2.41–43` |
| API VIP | `192.168.2.50` |
| Pod CIDR | `10.42.0.0/16` (K3s default) |
| Service CIDR | `10.43.0.0/16` (K3s default) |
| Storage | `local-path` (K3s default) |

## Notes

- Bundled K3s Traefik and ServiceLB are disabled; Traefik is installed via Helm with hostPort 80/443 on each node.
- To add worker-only nodes later, install K3s in agent mode with `--server https://<api-vip>:6443`.
