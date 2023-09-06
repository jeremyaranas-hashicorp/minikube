source ../common.sh

install_vault_helm_namespace_secondary
init_vault_namespace_secondary
unseal_vault_namespace_secondary

sleep 20

# Unseal nodes 
export VAULT_UNSEAL_KEY_SECONDARY=$(jq -r ".unseal_keys_b64[]" init-secondary.json)
kubectl exec -ti vault-secondary-1 -n vault -- vault operator unseal $VAULT_UNSEAL_KEY_SECONDARY
kubectl exec -ti vault-secondary-2 -n vault -- vault operator unseal $VAULT_UNSEAL_KEY_SECONDARY



