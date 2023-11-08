#!/usr/bin/env bash

./k8s_auth.sh
./postgresql-app-pod-jwt-auto-auth.sh
./jwt_auth_vault_agent_auto_auth.sh

source ../main/common.sh

login_to_vault
configure_test_secrets_engine
configure_k8s_auth
set_vault_policy
configure_k8s_auth_role
