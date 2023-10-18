#!/usr/bin/env bash

source ../main/common.sh

login_to_vault
configure_k8s_auth
configure_secrets_engine
set_vault_policy
configure_k8s_auth_role

# Install Vault Secrets Operator Helm chart 
helm install vault-secrets-operator hashicorp/vault-secrets-operator --version 0.1.0 -n vault-secrets-operator-system --create-namespace --values ../custom_resources/vault-operator-values.yaml

# Create a namespace for the k8s secret
kubectl create ns vso

# Set up k8s auth method for the secret
kubectl apply -f ../manifests/vault-auth-static.yaml

# Create the secret 
kubectl apply -f ../manifests/static-secret.yaml
