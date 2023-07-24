# Cleanup k8s auth method resources
kubectl delete sa -n test test-cloud
kubectl delete namespace test
kubectl delete sa vault-auth
kubectl delete clusterrolebindings.rbac.authorization.k8s.io role-tokenreview-binding
kubectl exec -ti vault-0 -- vault auth disable kubernetes

# Uninstall Vault Helm chart
helm uninstall vault
# Remove PVCs
kubectl delete pvc -l app.kubernetes.io/instance=vault 
# Remove files
rm -f *keys.json
rm -f replication/sat.txt

# Remove license
kubectl delete secrets vault-ent-license
