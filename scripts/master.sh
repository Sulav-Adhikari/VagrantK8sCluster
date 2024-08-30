#!/bin/bash

set -euxo pipefail

local_ip=$(ip --json a s | jq -r '.[] | if .ifname == "wlo1" or .ifname == "enp1s0" or .ifname == "eth1" then .addr_info[] | if .family == "inet" then .local else empty end else empty end')
NODENAME=$(hostname -s)
POD_CIDR="192.168.0.0/16"
OWNER=vagrant

sudo kubeadm config images pull

echo "Preflight Check Passed: Downloaded All Required Images"

# Step 7: Initialize kubeadm
echo "Initializing Kubernetes with kubeadm..."
sudo kubeadm init \
  --apiserver-advertise-address=$local_ip \
  --apiserver-cert-extra-sans=$local_ip \
  --pod-network-cidr=$POD_CIDR \
  --node-name $NODENAME \
  --ignore-preflight-errors=Swap \
  --skip-phases=addon/kube-proxy

# To start using your cluster, you need to run the following as a regular user:
echo "Setting kubeconfig for regular user..." 
mkdir -p /home/vagrant/.kube
sudo cp -i /etc/kubernetes/admin.conf /home/vagrant/.kube/config
sudo chown $OWNER:$OWNER /home/vagrant/.kube/config


# Save Configs to shared /Vagrant location

# For Vagrant re-runs, check if there is existing configs in the location and delete it for saving new configuration.

config_path="/vagrant/configs"

if [ -d $config_path ]; then
  rm -f $config_path/*
else
  mkdir -p $config_path
fi

cp -i /etc/kubernetes/admin.conf $config_path/config
touch $config_path/join.sh
chmod +x $config_path/join.sh

kubeadm token create --print-join-command > $config_path/join.sh

# Install cilium cli and install cilium
echo "Setting up cilium using clilium cli..."

CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
if [ "$(uname -m)" = "aarch64" ]; then CLI_ARCH=arm64; fi
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvf cilium-linux-${CLI_ARCH}.tar.gz -C /usr/local/bin
sudo rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}

# KUBECONFIG=/home/vagrant/.kube/config
# cilium install

#Setup kubens and kubectx
cd ~
wget https://raw.githubusercontent.com/ahmetb/kubectx/master/kubectx
wget https://raw.githubusercontent.com/ahmetb/kubectx/master/kubens
sudo chmod +x kubectx
sudo chmod +x kubens
mv kubens kubectx /usr/local/bin/
sudo chown -R vagrant:vagrant /home/vagrant/.kube
