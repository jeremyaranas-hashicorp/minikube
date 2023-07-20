# Enable auth method
kubectl exec -ti vault-0 -- vault auth enable kubernetes
# Configure k8s auth method to use the location of the k8s API
kubectl exec -ti vault-0 -- vault write auth/kubernetes/config \
      kubernetes_host="https://10.96.0.1:443"
# Write policy that enables read for the secrets at path
kubectl exec -ti vault-0 -- vault policy write internal-app - <<EOF
path "internal/database/config" {
   capabilities = ["read"]
}
EOF

# Create k8s auth role to connect k8s service account, namespace, Vault policy
kubectl exec -ti vault-0 -- vault write auth/kubernetes/role/internal-app \
      bound_service_account_names=internal-app,vault \
      bound_service_account_namespaces=default \
      policies=internal-app \
      ttl=24h
# Create k8s service account 
kubectl create sa internal-app