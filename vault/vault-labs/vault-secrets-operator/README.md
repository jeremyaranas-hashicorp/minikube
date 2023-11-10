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
```
minikube start -p vso
```
2. Install Vault Helm chart to deploy Vault cluster
```
./init-primary.sh
```

# Configure Vault Secrets Operator

1. Source file for common functions (these functions enable components that have been previously covered)
```
source common.sh
```
2. Login to Vault
```
login_to_vault
```
3. Enable k8s auth method
```
enable_k8s_auth
```
4. Configure k8s auth method 
```
configure_k8s_auth
```
5. Set Vault policy
```
set_vault_policy
```
6. Create Vault role for k8s auth method
```
configure_role
```
7. Set up Vault kv secrets engine
```
configure_secrets_engine
```
8. Update Helm repo
```
helm repo update
```
9. Install VSO Helm chart
```
helm install vault-secrets-operator hashicorp/vault-secrets-operator --version 0.3.3 -n vault-secrets-operator-system --create-namespace --values vault-operator-values.yaml
```
11. Check logs of VSO controller to confirm connection to Vault
```
kubectl logs -n vault-secrets-operator-system vault-secrets-operator-controller-manager-<12345>
```
```
2023-11-10T00:08:40Z	DEBUG	events	VaultConnection accepted	{"type": "Normal", "object": {"kind":"VaultConnection","namespace":"vault-secrets-operator-system","name":"default","uid":"c637c75a-f21a-40a8-aa4b-1da4fda5541d","apiVersion":"secrets.hashicorp.com/v1beta1","resourceVersion":"731"}, "reason": "Accepted"}
```
12. Create a k8s namespace called vso where the k8s secret will be stored 
```
kubectl create ns vso
```
13. Deploy Vauth auth custom resource to set up k8s authetication for the secret
```
kubectl apply -f vault-auth-static.yaml
```
14. Deploy Vault static secret custom resource to create the k8s secret secretkv in the vso namespace
```
kubectl apply -f static-secret.yaml
```
15.  Check that the Vault secret from the kv secrets engine has been added as a Kubernetes secret 
```
kubectl get secret -n vso secretkv -o jsonpath="{.data.password}" | base64 --decode
```
16.  Check logs of VSO controller to check secret sync status
```
kubectl logs -n vault-secrets-operator-system vault-secrets-operator-controller-manager-<12345> -f
```
```
2023-11-10T00:09:01Z	DEBUG	events	Secret synced	{"type": "Normal", "object": {"kind":"VaultStaticSecret","namespace":"vso","name":"vault-kv-app","uid":"873f578e-2299-44e9-a60b-4dce8302ad46","apiVersion":"secrets.hashicorp.com/v1beta1","resourceVersion":"774"}, "reason": "SecretSynced"}
```
17.  Update Vault secret 
```
kubectl exec -ti vault-0 -n vault -- vault kv put test/secret username="static-username" password="newPassword"
```
18. Check logs of VSO controller to check secret sync status
```
kubectl logs -n vault-secrets-operator-system vault-secrets-operator-controller-manager-<12345> -f
```
```
2023-11-10T18:19:03Z	DEBUG	events	Secret synced	{"type": "Normal", "object": {"kind":"VaultStaticSecret","namespace":"vso","name":"vault-kv-app","uid":"15da04fe-1217-401f-b60c-2fc7f4c8a3b6","apiVersion":"secrets.hashicorp.com/v1beta1","resourceVersion":"1664"}, "reason": "SecretRotated"}
```
19. Read Kubernetes secret to confirm that secret has been updated
```
kubectl get secret -n vso secretkv -o jsonpath="{.data.password}" | base64 --decode
```

# Cleanup

1. Run cleanup script to remove init.json and delete Minikube `vso` cluster 
```
./cleanup.sh
```

# References

1. https://hashicorp.atlassian.net/wiki/spaces/VSE/pages/2691433293/VSO+on+Openshift
2. https://developer.hashicorp.com/vault/tutorials/kubernetes/vault-secrets-operator
3. https://docs.google.com/presentation/d/1rre051TcABm4aMreYNbSURuheL-PFW0hHkHe5rlWiPg/edit#slide=id.g25b059dd4e8_0_0
4. https://developer.hashicorp.com/vault/docs/platform/k8s/vso/sources/vault
5. https://developer.hashicorp.com/vault/docs/platform/k8s/vso