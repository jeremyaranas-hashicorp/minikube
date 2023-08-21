helm uninstall vault -n vault

kubectl delete secret vault-server-tls -n vault
kubectl delete ns vault
kubectl delete csr vault-csr
kubectl delete pvc -l app.kubernetes.io/instance=vault 
