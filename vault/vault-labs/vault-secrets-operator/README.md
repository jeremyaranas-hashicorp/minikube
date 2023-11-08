This is a lab on setting up Vault Secrets Operator (VSO).

# Prerequisites

* `jq`
* `kubectl`
* `minikube`
* `VAULT_LICENSE` env variable (add to bashrc or zshrc)
* `kubectl` shortcut (optional)
  * Add to bashrc or zshrc
    * `alias k=kubectl`
    * `complete -o default -F __start_kubectl k`

# Set up cluster

1. Start minikube cluster
   1. `minikube start -p vso`
2. Install Vault Helm chart to deploy Vault cluster
   1. `./init-primary.sh`

# Configure Vault Secrets Operator

1. Source file for common functions (these functions enable components that have been previously covered)
   1. `source common.sh`
2. Login to Vault
   1. `login_to_vault`
3. Configure k8s auth method 
   1. `configure_k8s_auth`
4. Set Vault policy
   1. `set_vault_policy`
5. Create Vault role for k8s auth method
   1. `configure_role`
6. Set up Vault kv secrets engine
   1. `configure_secrets_engine`
7. Update Helm repo
   1. `helm repo update`
8. Install VSO Helm chart
   1. `helm install vault-secrets-operator hashicorp/vault-secrets-operator --version 0.3.3 -n vault-secrets-operator-system --create-namespace --values vault-operator-values.yaml`
9. Check logs of VSO controller
   1.  `kubectl logs -n vault-secrets-operator-system vault-secrets-operator-controller-manager-<123> -f`
   2. ```2023-11-08T20:26:58Z	DEBUG	events	VaultConnection accepted	{"type": "Normal", "object": {"kind":"VaultConnection","namespace":"vault-secrets-operator-system","name":"default","uid":"5ea4c2a9-d200-4dfb-a466-19a28a348ce7","apiVersion":"secrets.hashicorp.com/v1beta1","resourceVersion":"706"}, "reason": "Accepted"}```
10. Create a k8s namespace
    1.  `kubectl create ns vso`
11. Deploy Vauth auth custom resource
    1.  `kubectl apply -f vault-auth-static.yaml`
12. Deploy Vault static secret custom resource
    1.  `kubectl apply -f static-secret.yaml`
13. Check that Vault secret exists as a Kubernetes secret 
    1.  `kubectl get secret -n vso secretkv -o jsonpath="{.data.password}" | base64 --decode`

# References

1. https://hashicorp.atlassian.net/wiki/spaces/VSE/pages/2691433293/VSO+on+Openshift