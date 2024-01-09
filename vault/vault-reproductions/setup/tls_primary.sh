#!/usr/bin/env bash

source ../main/common.sh

if [ -n "$VAULT_LICENSE" ]; 
    then echo "VAULT_LICENSE environment variable is set" 
    else echo "VAULT_LICENSE environment variable is not set. Exiting script." 
    exit 1
     
fi

echo 'INFO: Removing existing certificates in /tmp/vault'
rm -fr /tmp/vault
sleep 5
echo 'INFO: Generating certificates for Vault primary'
../scripts/certs.sh
set_ent_license
helm install vault hashicorp/vault -f ../helm_chart_values_files/vault-values-tls-updated.yaml -n vault
init_vault
unseal_vault

echo 'INFO: Removing existing certificates in /tmp/vault-agent'
rm -fr /tmp/vault-agent
sleep 5
echo 'INFO: Generating certificates for Vault agent'
../scripts/certs-vault-agent.sh

export VAULT_UNSEAL_KEY=$(jq -r ".unseal_keys_b64[]" init.json)

sleep 10
echo 'INFO: Waiting for active node to be initialized'
sleep 10

kubectl exec -ti vault-1 -n vault -- vault operator unseal $VAULT_UNSEAL_KEY
kubectl exec -ti vault-2 -n vault -- vault operator unseal $VAULT_UNSEAL_KEY