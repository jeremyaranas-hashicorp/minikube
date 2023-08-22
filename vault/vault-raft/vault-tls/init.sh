source ../common.sh

set_ent_license_namespace
install_vault_helm_namespace
init_vault_namespace
unseal_vault_namespace

sleep 10

# Unseal nodes 
export VAULT_UNSEAL_KEY=$(jq -r ".unseal_keys_b64[]" init.json)
kubectl exec -ti vault-1 -n vault -- vault operator unseal $VAULT_UNSEAL_KEY
kubectl exec -ti vault-2 -n vault -- vault operator unseal $VAULT_UNSEAL_KEY



