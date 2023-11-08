#!/usr/bin/env bash

source ../common.sh

# Transit auto-unseal node

helm install vault-auto-unseal hashicorp/vault --values vault-values-auto-unseal.yaml
set_ent_license
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
# kubectl exec -ti vault-auto-unseal-0 -- vault token create -orphan -policy="autounseal" -wrap-ttl=120 -period=24h > wrapping_token.txt
kubectl exec -ti vault-auto-unseal-0 -- vault token create -orphan -policy=autounseal -period=24h -format=json > token.json
export TOKEN=$(jq -r ".auth.client_token" token.json)
# envsubst < vault-values.yaml

