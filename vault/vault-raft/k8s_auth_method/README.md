## Kubernetes Auth Method

From `vault-raft` directory

1. Install Vault Helm chart
   1. helm install vault hashicorp/vault --values vault-values.yaml"
2. Initialize Vault cluster
   1. ./init.sh

From the `k8s_auth_method` directory

1. Enable k8s auth method
   1. ./enable_k8s_auth.sh
