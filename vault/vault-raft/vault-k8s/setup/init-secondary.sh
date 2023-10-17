#!/usr/bin/env bash

source ../main/common.sh

if [ -n "$VAULT_LICENSE" ]; 
    then echo "VAULT_LICENSE environment variable is set" 
    else echo "VAULT_LICENSE environment variable is not set. Exiting script." 
    exit 1
fi

kubectl create ns vault-secondary

set_ent_license_secondary
install_vault_helm_secondary
init_vault_secondary
unseal_vault_secondary

sleep 20

# Unseal nodes 
export VAULT_UNSEAL_KEY_SECONDARY=$(jq -r ".unseal_keys_b64[]" init-secondary.json)
kubectl exec -ti vault-secondary-1 -n vault-secondary -- vault operator unseal $VAULT_UNSEAL_KEY_SECONDARY
kubectl exec -ti vault-secondary-2 -n vault-secondary -- vault operator unseal $VAULT_UNSEAL_KEY_SECONDARY



