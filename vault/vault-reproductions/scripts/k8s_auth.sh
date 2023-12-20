#!/usr/bin/env bash

source ../main/common.sh
login_to_vault
create_test_sa_resources

kubectl get clusterrolebindings.rbac.authorization.k8s.io | grep -q token-review-clusterrolebindings
if [ $? -eq 0 ] 
then 
  echo "INFO: token-review-clusterrolebindings ClusterRoleBinding already exist" 
else 
  echo "INFO: Creating ClusterRoleBinding" 
cat <<EOF | kubectl create -f -  
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
    name: test-sa  
    namespace: vault
  - kind: ServiceAccount  
    name: default
    namespace: vso
EOF
fi

enable_k8s_auth

# Retrieve the k8s CA certificate
KUBE_CA_CERT=$(kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.certificate-authority-data}' | base64 --decode)

# Retrieve the k8s host URL
KUBE_HOST=$(kubectl exec -ti -n vault vault-0 -- env | grep KUBERNETES_SERVICE_HOST | cut -d "=" -f2)

configure_k8s_auth
set_vault_policy
configure_test_secrets_engine
configure_k8s_auth_role
  
# Reference https://support.hashicorp.com/hc/en-us/articles/4404389946387