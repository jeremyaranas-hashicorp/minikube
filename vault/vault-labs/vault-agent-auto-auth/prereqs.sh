#!/usr/bin/env bash

source common.sh
login_to_vault
create_service_account
configure_secrets_engine
configure_k8s_auth
set_vault_policy
configure_k8s_auth_role
