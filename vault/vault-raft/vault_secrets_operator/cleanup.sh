# Uninstall Vault Helm chart
helm uninstall vault -n vault

# Uninstall Vault Secrets Operator
helm uninstall vault-secrets-operator -n vault-secrets-operator-system

# Remove PVCs
kubectl delete pvc -l app.kubernetes.io/instance=vault -n vault

# Remove files
rm -f *keys.json

# Remove license
kubectl delete secrets -n vault vault-ent-license

# Remove secrets
kubectl delete secrets -n vso test-k8s-secret

# Cleanup namespaces
kubectl delete ns vault vault-secrets-operator-system vso

