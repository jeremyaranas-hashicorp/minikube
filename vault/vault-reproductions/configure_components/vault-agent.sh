#!/usr/bin/env bash

source ../main/common.sh

login_to_vault
configure_test_secrets_engine
configure_k8s_auth
set_vault_policy
configure_k8s_auth_role

# Deploy application pod using postgresql-app-pod.sh
