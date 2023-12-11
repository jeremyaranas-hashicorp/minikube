#!/usr/bin/env bash

source ../main/common.sh

if [ -n "$VAULT_LICENSE" ]; 
    then echo "VAULT_LICENSE environment variable is set" 
    else echo "VAULT_LICENSE environment variable is not set. Exiting script." 
    exit 1
     
fi

kubectl create ns vault

helm install -n vault consul hashicorp/consul --values ../helm_chart_value_files/consul-values.yaml

set_ent_license
install_vault_with_consul_helm
init_vault
unseal_vault

sleep 10

# Unseal nodes 
export VAULT_UNSEAL_KEY=$(jq -r ".unseal_keys_b64[]" init.json)
# kubectl exec -ti vault-1 -n vault -- vault operator unseal $VAULT_UNSEAL_KEY
# kubectl exec -ti vault-2 -n vault -- vault operator unseal $VAULT_UNSEAL_KEY

# Set up audit logs
enable_audit_device
