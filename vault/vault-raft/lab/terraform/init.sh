#!/usr/bin/env bash

# Install kubectl
echo "INFO: Setting up kubectl"
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo mv kubectl /usr/local/bin/kubectl
chmod +x /usr/local/bin/kubectl

# Install minikube
echo "INFO: Setting up minikube"
sudo apt install -y curl wget apt-transport-https
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# Install helm
echo "INFO: Setting up helm"
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
sudo apt-get install apt-transport-https --yes
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update
sudo apt-get install helm
helm repo add hashicorp https://helm.releases.hashicorp.com

# Install jq
echo "INFO: Setting up jq"
sudo apt install -y jq

# Clone GitHub repo
echo "INFO: Setting GitHub repo"
git clone https://github.com/jeremyaranas-hashicorp/minikube.git

# Install docker
echo "INFO: Setting up docker"
sudo apt install software-properties-common curl apt-transport-https ca-certificates -y
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/trusted.gpg.d/docker-archive-keyring.gpg
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" -y
sudo apt install docker-ce docker-ce-cli containerd.io uidmap -y





# -------------------------------------------------------------------------------------------------------------------------------------------------




