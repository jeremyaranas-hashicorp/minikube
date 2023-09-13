helm uninstall vault -n vault
rm init.json
rm init-secondary.json
rm -fr /tmp/vault
rm sat.txt
kubectl delete ns vault
kubectl delete csr vault-csr
kubectl delete secrets -n vault vault-tls


