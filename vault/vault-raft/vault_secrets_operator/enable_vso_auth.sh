# Login to Vault
kubectl exec -ti vault-0 -n vault -- vault login $(jq -r ".root_token" cluster-a-keys.json)

# Enable k8s auth
kubectl exec -ti  vault-0 -n vault -- vault auth enable -path k8s-auth-method kubernetes

# Configure k8s auth method
# Minikube uses 10.96.0.1 for KUBERNETES_PORT_443_TCP_ADDR 
kubectl exec -ti vault-0 -n vault -- vault write auth/k8s-auth-method/config kubernetes_host="https://10.96.0.1:443" disable_local_ca_jwt=true disable_iss_validation=true kubernetes_ca_cert=@/run/secrets/kubernetes.io/serviceaccount/ca\.crt

# Enable secrets engine
kubectl exec -ti vault-0 -n vault -- vault secrets enable -path=kvv2 kv-v2

# Create secrets engine policy
kubectl exec -ti vault-0 -n vault -- vault policy write vso - <<EOF
path "*" {
   capabilities = ["read", "list"]
}
EOF

# Create a role in Vault to enable access to the secret
kubectl exec -ti  vault-0 -n vault -- vault write auth/k8s-auth-method/role/vso \
   bound_service_account_names=default \
   bound_service_account_namespaces="*" \
   audience="https://kubernetes.default.svc.cluster.local" \
   ttl=1h \
   token_policies=vso

# Create a secret in Vault
kubectl exec -ti  vault-0 -n vault -- vault kv put kvv2/test-vault-secret username="static-user" password="static-password"

# Install Vault Secrets Operator helm 
helm install vault-secrets-operator hashicorp/vault-secrets-operator --version 0.1.0 -n vault-secrets-operator-system --create-namespace --values vault-operator-values.yaml

# Create a namespace for the k8s secret
kubectl create ns vso

# Set up k8s auth method for the secret
kubectl apply -f vault-auth-static.yaml

# Create the secret in the app namespace
kubectl apply -f static-secret.yaml

# Create a cluster role binding with the cluster role system:auth-delegator for the service account name and namespace
cat <<EOF | kubectl create -f -  
---  
apiVersion: rbac.authorization.k8s.io/v1  
kind: ClusterRoleBinding  
metadata:  
  name: role-tokenreview-binding  
roleRef:  
  apiGroup: rbac.authorization.k8s.io  
  kind: ClusterRole  
  name: system:auth-delegator  
subjects:  
  - kind: ServiceAccount  
    name: default
    namespace: vso  
EOF
