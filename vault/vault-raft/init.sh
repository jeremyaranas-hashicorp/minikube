echo 'INFO: Starting Raft cluster setup'

# Configure primary 
kubectl exec vault-0 -- vault operator init -key-shares=1 -key-threshold=1 -format=json > cluster-keys.json
sleep 15s

echo 'INFO: vault-0 initialized'

# Unseal vault-0
export VAULT_UNSEAL_KEY=$(jq -r ".unseal_keys_b64[]" cluster-keys.json)
kubectl exec vault-0 -- vault operator unseal $VAULT_UNSEAL_KEY

echo 'INFO: Unsealed vault-0'

# Add nodes to clusters
kubectl exec -ti vault-1 -- vault operator raft join http://vault-0.vault-internal:8200
kubectl exec -ti vault-1 -- vault operator unseal $VAULT_UNSEAL_KEY
kubectl exec -ti vault-2 -- vault operator raft join http://vault-0.vault-internal:8200
kubectl exec -ti vault-2 -- vault operator unseal $VAULT_UNSEAL_KEY

echo 'INFO: Nodes added to primary'

# Configure secondary
kubectl exec vault-3 -- vault operator init -key-shares=1 -key-threshold=1 -format=json > cluster-keys-secondary.json
sleep 15

echo 'INFO: vault-3 initialized'

# Unseal vault-3
VAULT_UNSEAL_KEY_SECONDARY=$(jq -r ".unseal_keys_b64[]" cluster-keys-secondary.json)
kubectl exec vault-3 -- vault operator unseal $VAULT_UNSEAL_KEY_SECONDARY

echo 'INFO: Unsealed vault-3'

# Add nodes to clusters
kubectl exec -ti vault-4 -- vault operator raft join http://vault-3.vault-internal:8200
kubectl exec -ti vault-4 -- vault operator unseal $VAULT_UNSEAL_KEY_SECONDARY
kubectl exec -ti vault-5 -- vault operator raft join http://vault-3.vault-internal:8200
kubectl exec -ti vault-5 -- vault operator unseal $VAULT_UNSEAL_KEY_SECONDARY

echo 'INFO: Nodes added to secondary'

echo 'INFO: Raft cluster complete!'



