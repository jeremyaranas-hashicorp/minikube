#!/usr/bin/env bash

source ../main/common.sh

enable_k8s_auth
configure_test_secrets_engine
set_vault_policy
enable_k8s_auth_role

# Install Vault Secrets Operator Helm chart 
helm install vault-secrets-operator hashicorp/vault-secrets-operator --version 0.1.0 -n vault-secrets-operator-system --create-namespace --values ../custom_resources/vault-operator-values.yaml

# Create a namespace for the k8s secret
kubectl create ns vso

# Set up k8s auth method for the secret
kubectl apply -f ../manifests/vso-app-vault-auth.yaml

# Create the secret 
kubectl apply -f ../manifests/test-vault-static-secret.yaml
