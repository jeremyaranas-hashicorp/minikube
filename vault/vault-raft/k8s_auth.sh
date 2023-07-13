# Create a test namespace
kubectl create namespace test

# Create a service account and secret with the necessary permissions to allow the service account test-cloud to perform token reviews with k8s 
# test-cloud is the service account used to login to Vault using the k8s auth method
cat <<EOF | kubectl create -f -  
---  
apiVersion: v1
kind: ServiceAccount  
metadata:  
  name: test-cloud  
  namespace: test
---  
apiVersion: v1  
kind: Secret  
metadata:  
 name: test-cloud  
 namespace: test  
 annotations:  
   kubernetes.io/service-account.name: test-cloud  
type: kubernetes.io/service-account-token  
EOF

# Create a service account, secret and ClusterRoleBinding with the necessary permissions to allow Vault to perform token reviews with k8s
# vault-auth is service account where k8s auth is configured
# role-tokenreview-binding is the ClusterRoleBinding that the service accounts (vault-auth and test-cloud) need to be associated with
cat <<EOF | kubectl create -f -  
---  
apiVersion: v1  
kind: ServiceAccount  
metadata:  
  name: vault-auth  
---  
apiVersion: v1  
kind: Secret  
metadata:  
  name: vault-auth  
  annotations:  
    kubernetes.io/service-account.name: vault-auth  
type: kubernetes.io/service-account-token  
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
    name: vault-auth  
    namespace: default  
  - kind: ServiceAccount  
    name: test-cloud  
    namespace: test  
EOF

# EKS
# Create ClusterRole for system:auth-delegator
cat <<EOF | kubectl create -f -
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  annotations:
    rbac.authorization.kubernetes.io/autoupdate: "true"
  labels:
    kubernetes.io/bootstrapping: rbac-defaults
  name: system:auth-delegator
rules:
- apiGroups:
  - authentication.k8s.io
  resources:
  - tokenreviews
  verbs:
  - create
- apiGroups:
  - authorization.k8s.io
  resources:
  - subjectaccessreviews
  verbs:
  - create
EOF

# Login to Vault
kubectl exec vault-0 -- vault login $(jq -r ".root_token" cluster-a-keys.json)

# Enable k8s auth method in Vault
kubectl exec -ti vault-0 -- vault auth enable kubernetes

# Get the JWT for vault-auth service account in the default namespace to be used by Vault k8s config
VAULT_TOKEN_REVIEW_JWT=$(kubectl get secret vault-auth -o go-template='{{ .data.token }}' | base64 --decode)

# Retrieve the k8s CA certificate
KUBE_CA_CERT=$(kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.certificate-authority-data}' | base64 --decode)

# Retrieve the k8s host URL
KUBE_HOST=$(kubectl exec -ti vault-0 -- env | grep KUBERNETES_SERVICE_HOST | cut -d "=" -f2) # Minikube
KUBE_HOST=$(kubectl config view --raw --minify --flatten --output='jsonpath={.clusters[].cluster.server}') # EKS

# Configure the k8s auth method to use the vault-auth service account JWT, location of the k8s host and its certificate
kubectl exec -ti vault-0 -- vault write auth/kubernetes/config token_reviewer_jwt="$VAULT_TOKEN_REVIEW_JWT" kubernetes_host="https://10.96.0.1:443" kubernetes_ca_cert="$KUBE_CA_CERT" disable_local_ca_jwt="false" # Minikube
kubectl exec -ti vault-0 -- vault write auth/kubernetes/config token_reviewer_jwt="$VAULT_TOKEN_REVIEW_JWT" kubernetes_host="$KUBE_HOST" kubernetes_ca_cert="$KUBE_CA_CERT" disable_local_ca_jwt="true" # EKS

# Read the k8s config
kubectl exec -ti vault-0 -- vault read auth/kubernetes/config

# Write a policy to associate with the devweb-app role used for login by the test-cloud service account
kubectl exec -ti vault-0 -- vault policy write devwebapp - <<EOF
path "secret/data/devwebapp/config" {
  capabilities = ["read"]
}
EOF

# Associate the role to the test-cloud service account and the policy
kubectl exec -ti vault-0 -- vault write auth/kubernetes/role/devweb-app \
  bound_service_account_names=test-cloud \
  bound_service_account_namespaces=test \
  policies=devwebapp \
  ttl=24h
  
# Retrieve the JWT for test-cloud service account to login
CLIENT_TOKEN_REVIEW_JWT=$(kubectl get secret test-cloud -n test -o go-template='{{ .data.token }}' | base64 --decode)

# Perform a k8s login using test-cloud service account's JWT and the role
kubectl exec -ti vault-0 -- curl --request POST --data '{"jwt": "'$CLIENT_TOKEN_REVIEW_JWT'", "role": "devweb-app"}' http://127.0.0.1:8200/v1/auth/kubernetes/login