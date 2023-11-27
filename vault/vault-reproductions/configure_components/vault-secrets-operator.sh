#!/usr/bin/env bash

source ../main/common.sh

./k8s_auth.sh

kubectl exec -ti -n vault vault-0 -- vault write auth/kubernetes/config kubernetes_host="https://10.96.0.1:443"

# Install Vault Secrets Operator Helm chart 
helm install vault-secrets-operator hashicorp/vault-secrets-operator --version 0.3.3 -n vault-secrets-operator-system --create-namespace --values ../helm_chart_value_files/vault-operator-values.yaml

# Create a namespace for the k8s secret
kubectl create ns vso

# Set up k8s auth method for the secret
kubectl apply -f ../manifests/vso-vault-auth.yaml

# Create the secret 
kubectl apply -f ../manifests/vso-static-secret.yaml
