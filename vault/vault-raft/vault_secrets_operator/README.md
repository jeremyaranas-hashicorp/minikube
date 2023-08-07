# Vault Secrets Operator

This is a fork from https://github.com/hashicorp-education/learn-vault-secrets-operator.git

1. Start a new Minikube cluster
   1. `minikube start -p <cluster_name>`
2. Deploy Vault Helm and enable Vault Secrets Operator
   1. `./enable_vso.sh`
3. Get k8s secret
   1. `kubectl get secret -n vso test-k8s-secret -o jsonpath="{.data.password}" | base64 --decode`
4. Create a new secret 
   1. `./create_new_secret.sh`
5. Check that k8s secret was updated
   1. `kubectl get secret -n vso test-k8s-secret -o jsonpath="{.data.password}" | base64 --decode`

* Run cleanup script
  * `./cleanup.sh`

