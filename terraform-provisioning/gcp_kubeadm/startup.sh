#! /bin/bash
apt-get update
apt-get install libseccomp2 apt-transport-https curl -y
export VERSION="1.3.0"
wget https://storage.googleapis.com/cri-containerd-release/cri-containerd-${VERSION}.linux-amd64.tar.gz
tar --no-overwrite-dir -C / -xzf cri-containerd-${VERSION}.linux-amd64.tar.gz
echo \"overlay\nbr_netfilter\" >> /etc/modules
systemctl enable containerd
modprobe overlay
modprobe br_netfilter
cat > /etc/sysctl.d/99-kubernetes-cri.conf <<EOF
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sysctl --system
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update
apt-get install -y kubelet kubeadm kubectl
apt-mark hold kubelet kubeadm kubectl
export DEBIAN_FRONTEND=noninteractive
ARCH=$(arch)
BRANCH="${BRANCH:-master}"
source /etc/os-release
echo 'deb http://download.opensuse.org/repositories/home:/katacontainers:/releases:/${ARCH}:/${BRANCH}/Debian_${VERSION_ID}/ /' > /etc/apt/sources.list.d/kata-containers.list
curl -sL  http://download.opensuse.org/repositories/home:/katacontainers:/releases:/${ARCH}:/${BRANCH}/Debian_${VERSION_ID}/Release.key | sudo apt-key add -
apt-get update
apt-get -y install kata-runtime kata-proxy kata-shim
mkdir /etc/containerd
containerd config default > /etc/containerd/config.toml
sed -i '/containerd.untrusted_workload_runtime/{n;s/\"\"/\"io.containerd.kata.v2\"/}' /etc/containerd/config.toml
systemctl restart containerd