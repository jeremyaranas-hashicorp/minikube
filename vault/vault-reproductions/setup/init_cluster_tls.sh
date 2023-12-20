#!/usr/bin/env bash

source ../main/common.sh

if [ -n "$VAULT_LICENSE" ]; 
    then echo "VAULT_LICENSE environment variable is set" 
    else echo "VAULT_LICENSE environment variable is not set. Exiting script." 
    exit 1
     
fi

rm -fr /tmp/vault
sleep 5
../scripts/certs.sh
set_ent_license
helm install vault hashicorp/vault -f ../helm_chart_values_files/vault-values-tls.yaml -n vault
init_vault
unseal_vault

export VAULT_UNSEAL_KEY=$(jq -r ".unseal_keys_b64[]" init.json)

sleep 10
echo 'INFO: Waiting for active node to be initialized'
sleep 10

kubectl exec -ti vault-1 -n vault -- vault operator unseal $VAULT_UNSEAL_KEY
kubectl exec -ti vault-2 -n vault -- vault operator unseal $VAULT_UNSEAL_KEY

rm -fr /tmp/vault-secondary
sleep 5
../scripts/certs-secondary.sh
set_ent_license_secondary
helm install vault-secondary hashicorp/vault -f ../helm_chart_values_files/vault-values-secondary-tls.yaml -n vault-secondary
init_vault_secondary
unseal_vault_secondary

export VAULT_UNSEAL_KEY_SECONDARY=$(jq -r ".unseal_keys_b64[]" init-secondary.json)

sleep 10
echo 'INFO: Waiting for active node to be initialized'
sleep 10

kubectl exec -ti vault-secondary-1 -n vault-secondary -- vault operator unseal $VAULT_UNSEAL_KEY_SECONDARY
kubectl exec -ti vault-secondary-2 -n vault-secondary -- vault operator unseal $VAULT_UNSEAL_KEY_SECONDARY