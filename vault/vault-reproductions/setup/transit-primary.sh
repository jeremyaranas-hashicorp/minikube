#!/usr/bin/env bash

source ../main/common.sh

kubectl create ns vault

helm install -n vault vault-auto-unseal hashicorp/vault --values ../helm_chart_values_files/vault-values-auto-unseal-updated.yaml
set_ent_license_auto_unseal_pod
init_vault_auto_unseal
unseal_vault_auto_unseal
login_to_vault_auto_unseal

kubectl exec -ti -n vault vault-auto-unseal-0 -- vault secrets enable transit
kubectl exec -ti -n vault vault-auto-unseal-0 -- vault write -f transit/keys/autounseal

kubectl exec -ti -n vault vault-auto-unseal-0 -- tee /tmp/autounseal.hcl <<EOF
path "transit/encrypt/autounseal" {
   capabilities = [ "update" ]
}

path "transit/decrypt/autounseal" {
   capabilities = [ "update" ]
}
EOF

kubectl exec -ti -n vault vault-auto-unseal-0 -- vault policy write autounseal  /tmp/autounseal.hcl
kubectl exec -ti -n vault vault-auto-unseal-0 -- vault token create -orphan -policy=autounseal -period=24h -format=json > token.json
export TOKEN=$(jq -r ".auth.client_token" token.json)
envsubst < ../helm_chart_values_files/vault-values-transit.yaml > ../helm_chart_values_files/vault-values-transit-updated.yaml

helm install -n vault vault hashicorp/vault --values ../helm_chart_values_files/vault-values-transit-updated.yaml 
set_ent_license_transit
init_vault_using_auto_unseal
sleep 10