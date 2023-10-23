# Vault cluster

source ../common.sh

helm install vault hashicorp/vault --values vault-values.yaml
set_ent_license
init_vault_using_auto_unseal
sleep 10

