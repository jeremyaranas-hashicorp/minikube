helm uninstall vault -n vault
helm uninstall vault-secondary -n vault

kubectl delete secret vault-tls -n vault
kubectl delete ns vault
kubectl delete csr vault-csr
kubectl delete pvc -l app.kubernetes.io/instance=vault 

rm init.json
rm init-secondary.json