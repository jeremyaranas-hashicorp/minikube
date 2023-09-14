helm uninstall vault -n vault
helm uninstall vault -n vault-secondary
rm init.json
rm init-secondary.json
rm -fr /tmp/vault
rm sat.txt
kubectl delete ns vault
kubectl delete ns vault-secondary
kubectl delete csr vault-csr
kubectl delete csr vault-csr-secondary
kubectl delete secrets -n vault vault-tls
kubectl delete secrets -n vault vault-tls-secondary



