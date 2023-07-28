# Login with root token
kubectl exec vault-0 -- vault login $(jq -r ".root_token" cluster-a-keys.json)
# Enable secrets engine
kubectl exec -ti vault-0 -- vault secrets enable -path=test kv
# Add secret
kubectl exec -ti vault-0 -- vault kv put test/secret/super_secret username="bob" password="1234"

# Enable auth method
kubectl exec -ti vault-0 -- vault auth enable kubernetes
# Configure k8s auth method to use the location of the k8s API
kubectl exec -ti vault-0 -- vault write auth/kubernetes/config \
      kubernetes_host="https://10.96.0.1:443"
# Write policy that enables read for the secrets at path
kubectl exec -ti vault-0 -- vault policy write test-app - <<EOF
path "test/secret/super_secret" {
   capabilities = ["read"]
}
EOF

# Create k8s auth role to connect k8s service account, namespace, Vault policy
kubectl exec -ti vault-0 -- vault write auth/kubernetes/role/test-app \
      bound_service_account_names=vault-nginx-sa \
      bound_service_account_namespaces=default \
      policies=test-app \
      ttl=24h
# Create k8s service account 
kubectl create sa vault-nginx-sa