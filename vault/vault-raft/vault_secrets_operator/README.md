# Vault Secrets Operator

This is a fork from https://github.com/hashicorp-education/learn-vault-secrets-operator.git

1. Deploy Vault Helm and enable Vault Secrets Operator
   1. `./enable_vso.sh`
2. Get k8s secret
   1. `kubectl get secret -n vso test-k8s-secret -o jsonpath="{.data.password}" | base64 --decode`
3. Create a new secret 
   1. `./create_new_secret.sh`
4. Check that k8s secret was updated
   1. `kubectl get secret -n vso test-k8s-secret -o jsonpath="{.data.password}" | base64 --decode`

* Run cleanup script
  * `./cleanup.sh`

