#!/usr/bin/env bash

source ../main/common.sh
login_to_vault

kubectl exec -ti -n vault vault-0 -- touch /vault/audit/audit.log
kubectl exec -ti -n vault vault-0 -- chown vault:vault /vault/audit/audit.log
kubectl exec -ti -n vault vault-0 -- vault audit enable file file_path=/vault/audit/audit.log