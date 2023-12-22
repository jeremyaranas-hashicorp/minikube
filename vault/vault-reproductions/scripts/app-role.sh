#!/usr/bin/env bash

kubectl exec -ti -n vault vault-0 -- vault auth enable approle

kubectl exec -ti -n vault vault-0 -- vault write auth/approle/role/my-app-role \
    secret_id_ttl=10m \
    token_ttl=20m \
    token_max_ttl=30m \
    token_policies=test-policy

ROLE_ID=$(kubectl exec -ti -n vault vault-0 -- vault read -format=json auth/approle/role/my-app-role/role-id | jq -r .data.role_id)

SECRET_ID=$(kubectl exec -ti -n vault vault-0 -- vault write -format=json -f auth/approle/role/my-app-role/secret-id | jq -r .data.secret_id)

kubectl exec -ti -n vault vault-0 -- vault write auth/approle/login \
    role_id=$ROLE_ID \
    secret_id=$SECRET_ID