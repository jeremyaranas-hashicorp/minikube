#!/usr/bin/env bash

kubectl apply -f ../manifests/postgres-config.yaml
kubectl apply -f ../manifests/postgres-pvc-pv.yaml
kubectl apply -f ../manifests/postgres-deployment.yaml 
kubectl apply -f ../manifests/postgres-service.yaml

# Create service account for postgres pod in default namespace
kubectl create sa postgres-sa

# Create ClusterRoleBinding for service account
cat <<EOF | kubectl create -f -  
---  
apiVersion: rbac.authorization.k8s.io/v1  
kind: ClusterRoleBinding  
metadata:  
  name: postgres-token-review-clusterrolebindings  
roleRef:  
  apiGroup: rbac.authorization.k8s.io  
  kind: ClusterRole  
  name: system:auth-delegator  
subjects: 
  - kind: ServiceAccount  
    name: postgres-sa  
    namespace: default
EOF
