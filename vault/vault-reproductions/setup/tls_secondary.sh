#!/usr/bin/env bash

source ../main/common.sh

if [ -n "$VAULT_LICENSE" ]; 
    then echo "VAULT_LICENSE environment variable is set" 
    else echo "VAULT_LICENSE environment variable is not set. Exiting script." 
    exit 1
     
fi

echo 'INFO: Removing existing certificates in /tmp/vault-secondary'
rm -fr /tmp/vault-secondary
sleep 5
echo 'INFO: Generating certificates for Vault secondary'
../scripts/certs-secondary.sh
set_ent_license_secondary
helm install vault-secondary hashicorp/vault -f ../helm_chart_values_files/vault-values-secondary-tls-updated.yaml -n vault-secondary
init_vault_secondary
unseal_vault_secondary

export VAULT_UNSEAL_KEY_SECONDARY=$(jq -r ".unseal_keys_b64[]" init-secondary.json)

sleep 10
echo 'INFO: Waiting for active node to be initialized'
sleep 10

kubectl exec -ti vault-secondary-1 -n vault-secondary -- vault operator unseal $VAULT_UNSEAL_KEY_SECONDARY
kubectl exec -ti vault-secondary-2 -n vault-secondary -- vault operator unseal $VAULT_UNSEAL_KEY_SECONDARY