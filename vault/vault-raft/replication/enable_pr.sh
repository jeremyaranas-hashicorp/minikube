#!/usr/bin/env bash

source ../common.sh

helm install vault hashicorp/vault --values vault-values.yaml
set_ent_license
init_vault
unseal_vault
sleep 10
# Unseal nodes 
export VAULT_UNSEAL_KEY=$(jq -r ".unseal_keys_b64[]" init.json)
kubectl exec -ti vault-1 -- vault operator unseal $VAULT_UNSEAL_KEY
kubectl exec -ti vault-2 -- vault operator unseal $VAULT_UNSEAL_KEY

helm install vault-secondary hashicorp/vault --values vault-values-secondary.yaml
init_vault_2
unseal_vault_2
sleep 20

# Unseal nodes 
export VAULT_UNSEAL_KEY_2=$(jq -r ".unseal_keys_b64[]" init-2.json)
kubectl exec -ti vault-secondary-1 -- vault operator unseal $VAULT_UNSEAL_KEY_2
kubectl exec -ti vault-secondary-2 -- vault operator unseal $VAULT_UNSEAL_KEY_2

# Log into vault-0
login_to_vault

# Enable replication on primary
kubectl exec -ti vault-0 -- vault write -f sys/replication/dr/primary/enable

# Genrerate secondary activation token
kubectl exec -ti vault-0 -- vault write sys/replication/dr/primary/secondary-token id=pr_secondary -format=json | jq -r .wrap_info.token > sat.txt

# Log into vault-secondary-0
source ../common.sh
login_to_vault_2

# Enable replication on secondary
kubectl exec -ti vault-secondary-0 -- vault write sys/replication/dr/secondary/enable token=$(cat sat.txt)