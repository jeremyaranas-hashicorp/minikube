#!/usr/bin/env bash

source ./common.sh





login_to_vault
configure_k8s_auth
configure_secrets_engine
set_vault_policy
configure_k8s_auth_role

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
  name: token-review-clusterrolebindings
roleRef:  
  apiGroup: rbac.authorization.k8s.io  
  kind: ClusterRole  
  name: system:auth-delegator  
subjects:  
  - kind: ServiceAccount  
    name: default
    namespace: vso  
EOF