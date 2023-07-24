# Delete sa
kubectl delete sa internal-app

# Delete deployment
kubectl delete deployment orgchart

# Uninstall Vault Helm chart
helm uninstall vault

# Remove PVCs
kubectl delete pvc -l app.kubernetes.io/instance=vault 

# Remove files
rm -f *keys.json

# Remove license
kubectl delete secrets vault-ent-license