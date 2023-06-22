# Uninstall Vault Helm chart
helm uninstall vault
# Remove PVCs
kubectl delete pvc -l app.kubernetes.io/instance=vault 