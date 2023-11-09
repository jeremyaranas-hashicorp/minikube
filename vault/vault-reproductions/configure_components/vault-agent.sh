#!/usr/bin/env bash

./k8s_auth.sh
./postgresql-app-pod.sh

source ../main/common.sh

login_to_vault
configure_test_secrets_engine
enable_k8s_auth
set_vault_policy
configure_k8s_auth_role

