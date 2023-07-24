## Kubernetes Auth Method

This is a fork from https://github.com/hashicorp-education/learn-vault-secrets-operator.git

From the `vault_secrets_operator` directory

1. Install Vault helm
   1. helm install vault hashicorp/vault -n vault --create-namespace --values vault-values.yaml
2. Initialize and unseal Vault 
   1. ./init.sh
3. . Enable k8s auth
   1. ./enable_k8s_auth.sh
4. Install Vault Secrets Operator helm 
   1. helm install vault-secrets-operator hashicorp/vault-secrets-operator --version 0.1.0 -n vault-secrets-operator-system --create-namespace --values vault-operator-values.yaml
5. Deploy secret
   1. ./deploy_secrets.sh
6. Get k8s secret
   1. kubectl get secret -n app secretkv -o jsonpath="{.data.password}" | base64 --decode
7. Create a new secret 
   1. ./create_new_secret.sh
8.  Check that secret was updated
   1.  kubectl get secret -n app secretkv -o jsonpath="{.data.password}" | base64 --decode