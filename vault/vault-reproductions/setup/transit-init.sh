#!/usr/bin/env bash

source ../main/common.sh

helm install vault-auto-unseal hashicorp/vault --values ../helm_chart_value_files/vault-values-auto-unseal.yaml
set_ent_license_auto_unseal_pod
init_vault_auto_unseal
unseal_vault_auto_unseal
login_to_vault_auto_unseal

kubectl exec -ti vault-auto-unseal-0 -- vault secrets enable transit
kubectl exec -ti vault-auto-unseal-0 -- vault write -f transit/keys/autounseal

kubectl exec -ti vault-auto-unseal-0 -- tee /tmp/autounseal.hcl <<EOF
path "transit/encrypt/autounseal" {
   capabilities = [ "update" ]
}

path "transit/decrypt/autounseal" {
   capabilities = [ "update" ]
}
EOF

kubectl exec -ti vault-auto-unseal-0 -- vault policy write autounseal  /tmp/autounseal.hcl
kubectl exec -ti vault-auto-unseal-0 -- vault token create -orphan -policy=autounseal -period=24h -format=json > token.json
export TOKEN=$(jq -r ".auth.client_token" token.json)
rm -f ../helm_chart_value_files/vault-values-transit-updated.yaml
envsubst < ../helm_chart_value_files/vault-values-transit.yaml > ../helm_chart_value_files/vault-values-transit-updated.yaml

