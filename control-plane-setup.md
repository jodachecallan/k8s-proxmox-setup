# To be configured on both control plane and node

# Install containerd and CNI
apt install containerd
systemctl status containerd
mkdir /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
vi /etc/containerd/config.toml
# update file: SystemdCgroup = true

# diable swap
sudo swapoff -a
cat /proc/swaps
free -h
# vi /etc/fstab

# enable bridging (option1)
vi /etc/sysctl.conf 
# Uncomment net.ipv4.ip_forward=1

# enable bridging (option2)
cat <<EOF | sudo tee /etc/sysctl.d/kubernetes.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system

# create bridge net filter
vi /etc/modules-load.d/k8s.conf
# add txt 
br_netfilter

sudo apt-get install -y apt-transport-https ca-certificates curl

# Get the version on kubernetes you want
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.27/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.27/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt-get update
apt list --all-versions kubectl
sudo apt-get install -y kubelet=1.27.14-1.1 kubeadm=1.27.14-1.1 kubectl=1.27.14-1.1
sudo apt-mark hold kubelet kubeadm kubectl

# This section is for the control plane only
    kubeadm init --control-plane-endpoint 192.168.2.40 --node-name k8s-server1 --pod-network-cidr 10.244.0.0/16 --dry-run
    kubeadm init --control-plane-endpoint 192.168.2.40 --node-name k8s-server1 --pod-network-cidr 10.244.0.0/16

    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config

    kubectl apply -f https://github.com/flannel-io/flannel/releases/latest/download/kube-flannel.yml

# Get and Run the join cmd on the nodes
# kubeadm token create --print-join-command