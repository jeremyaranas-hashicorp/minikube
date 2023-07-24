# CSI Provider

1. Install Vault Helm chart
   1. `helm install vault hashicorp/vault --values vault-values.yaml`
2. Initialize Vault cluster
   1. `./init.sh`
3. Set up CSI
   1. ./enable_csi.sh

* Run cleanup script
  * `./cleanup.sh`

References:

https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-secret-store-driver

