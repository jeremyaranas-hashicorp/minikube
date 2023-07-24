# Login to Vault
kubectl exec -ti vault-0 -n vault -- vault login $(jq -r ".root_token" cluster-a-keys.json)

# Enable k8s auth
kubectl exec -ti  vault-0 -n vault -- vault auth enable -path demo-auth-mount kubernetes

# Configure k8s auth method
# Minikube uses 10.96.0.1 for KUBERNETES_PORT_443_TCP_ADDR 
kubectl exec -ti vault-0 -n vault -- vault write auth/demo-auth-mount/config \
   kubernetes_host="https://10.96.0.1:443"

# Enable secrets engine
kubectl exec -ti vault-0 -n vault -- vault secrets enable -path=kvv2 kv-v2

# Create secrets engine policy
kubectl exec -ti vault-0 -n vault -- vault policy write dev - <<EOF
path "kvv2/*" {
   capabilities = ["read"]
}
EOF


# Create a role in Vault to enable access to the secret
kubectl exec -ti  vault-0 -n vault -- vault write auth/demo-auth-mount/role/role1 \
   bound_service_account_names=default \
   bound_service_account_namespaces=app \
   policies=dev \
   audience=vault \
   ttl=24h

# Create a secret in Vault
kubectl exec -ti  vault-0 -n vault -- vault kv put kvv2/webapp/config username="static-user" password="static-password"

