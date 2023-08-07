#!/usr/bin/env bash

source ../common.sh
install_vault_helm
set_ent_license
init_vault
unseal_vault
add_nodes_to_cluster
login_to_vault
configure_secrets_engine
configure_k8s_auth
set_vault_policy
configure_k8s_auth_role

# Deploy application pod
kubectl apply --filename nginx-deployment.yaml

