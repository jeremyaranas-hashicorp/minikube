# Configure primary 
kubectl exec vault-0 -n vault-namespace -- vault operator init -key-shares=1 -key-threshold=1 -format=json > cluster-keys.json
sleep 15s

echo 'INFO: vault-0 initialized'

# Unseal vault-0
export VAULT_UNSEAL_KEY=$(jq -r ".unseal_keys_b64[]" cluster-keys.json)
kubectl exec vault-0 -n vault-namespace -- vault operator unseal $VAULT_UNSEAL_KEY

echo 'INFO: Unsealed vault-0'




