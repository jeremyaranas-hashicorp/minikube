This Terraform will spin up an EC2 instance and setup the environment to run the k8s training labs.

# Prerequisites

1. Edit *terraform.tfvars*
   1. Updated `key_name` to match key name in EC2

# Instructions

1. `terraform init`
2. `terraform apply --auto-approve`
3. ssh to EC2 instance
4. Run the following commands 
   1. `sudo usermod -aG docker $USER`
   2. `newgrp docker`
5. Export Vault license
   1. `export VAULT_LICENSE=<string>`
6. Start Minikube 
   1. `minikube start`
7. cd to directory
   1. `cd ~/minikube/vault/vault-raft/lab/vault_agent_injector`
8. Run script
   1. `./setup.sh`