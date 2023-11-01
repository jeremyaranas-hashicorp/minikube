#!/usr/bin/env bash

source ../main/common.sh

login_to_vault
configure_test_secrets_engine
configure_k8s_auth
set_vault_policy
configure_k8s_auth_role

# Deploy application pod
kubectl apply --filename ../manifests/web-app-deployment.yaml
kubectl apply --filename ../manifests/postgres-deployment.yaml
