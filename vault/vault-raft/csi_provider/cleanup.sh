# Uninstall Helm charts
helm uninstall vault
helm uninstall csi

# Remove PVCs
kubectl delete pvc -l app.kubernetes.io/instance=vault 

# Remove files
rm -f *keys.json

# Remove license
kubectl delete secrets vault-ent-license

# Remove sa
kubectl delete sa webapp-sa

# Remove secret provider class
kubectl delete secretproviderclass vault-database