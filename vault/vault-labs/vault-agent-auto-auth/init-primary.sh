#!/usr/bin/env bash

source common.sh

if [ -n "$VAULT_LICENSE" ]; 
    then echo "VAULT_LICENSE environment variable is set" 
    else echo "VAULT_LICENSE environment variable is not set. Exiting script." 
    exit 1
     
fi

kubectl create ns vault

set_ent_license
install_vault_helm
init_vault
unseal_vault

sleep 10

# Unseal nodes 
export VAULT_UNSEAL_KEY=$(jq -r ".unseal_keys_b64[]" init.json)
kubectl exec -ti vault-1 -n vault -- vault operator unseal $VAULT_UNSEAL_KEY
kubectl exec -ti vault-2 -n vault -- vault operator unseal $VAULT_UNSEAL_KEY



