# Vault Secrets Operator

This is a fork from https://github.com/hashicorp-education/learn-vault-secrets-operator.git

1. Install Vault helm
   1. `helm install vault hashicorp/vault -n vault --create-namespace --values vault-values.yaml`
2. Initialize and unseal Vault 
   1. `./init.sh`
3. . Enable k8s auth
   1. `./enable_vso.sh`

* Get k8s secret
  * `kubectl get secret -n app secretkv -o jsonpath="{.data.password}" | base64 --decode`
* Create a new secret 
  * `./create_new_secret.sh`
* Check that secret was updated
  * `kubectl get secret -n app secretkv -o jsonpath="{.data.password}" | base64 --decode`

* Run cleanup script
  * `./cleanup.sh`

