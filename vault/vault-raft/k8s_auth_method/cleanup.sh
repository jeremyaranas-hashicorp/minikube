# Cleanup k8s auth method resources
kubectl delete namespace test-namespace
kubectl delete sa test-sa
kubectl delete clusterrolebindings.rbac.authorization.k8s.io token-review-clusterrolebindings
kubectl exec -ti vault-0 -- vault auth disable kubernetes

# Uninstall Vault Helm chart
helm uninstall vault

# Remove PVCs
kubectl delete pvc -l app.kubernetes.io/instance=vault 

# Remove files
rm -f init.json

# Remove license
kubectl delete secrets vault-ent-license
