# Manual steps and troubleshooting

## Verify cluster bootstrap

After `tofu apply`, wait a few minutes for cloud-init to finish on all nodes.

```bash
ssh ubuntu@192.168.2.41 'cloud-init status --wait'
ssh ubuntu@192.168.2.41 'sudo k3s kubectl get nodes -o wide'
```

Expected: three nodes in `Ready` state.

Check bootstrap logs on a node:

```bash
ssh ubuntu@192.168.2.41 'sudo journalctl -u k3s -n 50 --no-pager'
```

## Kubeconfig

### Admin kubeconfig (full access)

From any server node:

```bash
ssh ubuntu@192.168.2.41 'sudo cat /etc/rancher/k3s/k3s.yaml' > kubeconfig
```

Replace the server URL:

- Before kube-vip: `https://192.168.2.41:6443`
- After kube-vip: `https://192.168.2.50:6443`

```bash
export KUBECONFIG=$PWD/kubeconfig
kubectl get nodes
```

### Limited admin via service account

Create a dedicated admin service account:

```bash
kubectl create serviceaccount adminuser -n kube-system
kubectl create clusterrolebinding adminuser-admin \
  --clusterrole=cluster-admin \
  --serviceaccount=kube-system:adminuser

kubectl create token adminuser -n kube-system --duration=8760h
```

Build a kubeconfig with the token and CA data from the cluster:

```bash
kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}'
```

## kube-vip

Before applying, confirm the VIP in `cluster/kube-vip/daemonset.yaml` matches `api_vip` in your `terraform.tfvars` (default `192.168.2.50`).

Verify the VIP is reachable:

```bash
curl -k https://192.168.2.50:6443/readyz
```

If the VIP does not appear, check the network interface name on your VMs (`ip link`) and update `vip_interface` in the daemonset if it is not `eth0`.

## Traefik external access

Traefik runs as a DaemonSet with hostPort 80/443 on each node. Point app DNS A records at one or more node IPs (`192.168.2.41`–`43`).

Check Traefik status:

```bash
kubectl get pods -n traefik -o wide
kubectl get svc -n traefik
```

## cert-manager and TLS

Confirm the ClusterIssuer is ready:

```bash
kubectl get clusterissuer letsencrypt-prod
```

Check certificate issuance for an Ingress:

```bash
kubectl get certificate -A
kubectl describe certificate <name>
```

Ensure the Ingress hostname resolves to a node IP that reaches Traefik on port 80 (required for HTTP-01 challenge). Cluster DNS must also resolve public names (e.g. `acme-v2.api.letsencrypt.org`) for ACME registration.

## Re-provisioning a node

If a node fails and needs replacement:

1. Remove the failed VM from Proxmox (or run `tofu destroy -target=...` for that node).
2. Re-run `tofu apply` to recreate it.
3. The node rejoins using the same pre-shared `k3s_token`.

## Destroy the cluster

```bash
cd terraform
tofu destroy
```

This removes all three VMs. Persistent data on node disks is deleted with the VMs.
