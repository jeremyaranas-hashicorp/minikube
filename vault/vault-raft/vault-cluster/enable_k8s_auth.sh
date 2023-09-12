source ./common.sh

cat <<EOF | kubectl create -f -  
---  
apiVersion: v1
kind: ServiceAccount  
metadata:  
  name: test-sa  
  namespace: vault
---  
apiVersion: v1  
kind: Secret  
metadata:  
 name: test-sa  
 namespace: vault
 annotations:  
   kubernetes.io/service-account.name: test-sa  
type: kubernetes.io/service-account-token  
EOF

cat <<EOF | kubectl create -f -  
---  
apiVersion: v1  
kind: ServiceAccount  
metadata:  
  name: vault  
---  
apiVersion: v1  
kind: Secret  
metadata:  
  name: vault
  annotations:  
    kubernetes.io/service-account.name: vault
type: kubernetes.io/service-account-token  
---  
apiVersion: rbac.authorization.k8s.io/v1  
kind: ClusterRoleBinding  
metadata:  
  name: token-review-clusterrolebindings  
roleRef:  
  apiGroup: rbac.authorization.k8s.io  
  kind: ClusterRole  
  name: system:auth-delegator  
subjects:  
  - kind: ServiceAccount  
    name: vault
    namespace: default  
  - kind: ServiceAccount  
    name: test-sa  
    namespace: vault
EOF

source ./common.sh
configure_k8s_auth

# Get the JWT for vault-sa service account in the default namespace to be used by Vault k8s config
VAULT_TOKEN_REVIEW_JWT=$(kubectl get secret vault -o go-template='{{ .data.token }}' | base64 --decode)

# Retrieve the k8s CA certificate
KUBE_CA_CERT=$(kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.certificate-authority-data}' | base64 --decode)

# Retrieve the k8s host URL
KUBE_HOST=$(kubectl exec -ti vault-0 -- env | grep KUBERNETES_SERVICE_HOST | cut -d "=" -f2)

# Configure the k8s auth method to use the vault service account JWT, location of the k8s host and its certificate
kubectl exec -ti vault-0 -- vault write auth/kubernetes/config token_reviewer_jwt="$VAULT_TOKEN_REVIEW_JWT" kubernetes_host="https://10.96.0.1:443" kubernetes_ca_cert="$KUBE_CA_CERT" disable_local_ca_jwt="true"

# Read the k8s config
kubectl exec -ti vault-0 -- vault read auth/kubernetes/config

# Write a policy to associate with the devweb-app role used for login by the test-sa service account
source ../common.sh
set_vault_policy

# Associate the role to the test-sa service account and the policy
configure_k8s_auth_role
  
# Reference https://support.hashicorp.com/hc/en-us/articles/4404389946387
