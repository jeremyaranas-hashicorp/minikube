#!/usr/bin/env bash

source ../main/common.sh
create_test_sa_resources
create_clusterrolebinding_for_jwt_auth
enable_jwt_auth
write_jwt_config
create_jwt_role_for_app_pod

# Reference https://developer.hashicorp.com/vault/docs/auth/jwt/oidc-providers/kubernetes