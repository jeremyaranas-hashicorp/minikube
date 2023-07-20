echo 'INFO: Starting Raft cluster setup'

# Configure cluster A
kubectl exec vault-0 -- vault operator init -key-shares=1 -key-threshold=1 -format=json > cluster-a-keys.json
sleep 30

echo 'INFO: vault-0 initialized'

# Unseal vault-0
export VAULT_UNSEAL_KEY_CLUSTER_A=$(jq -r ".unseal_keys_b64[]" cluster-a-keys.json)
kubectl exec vault-0 -- vault operator unseal $VAULT_UNSEAL_KEY_CLUSTER_A

echo 'INFO: Unsealed vault-0'
sleep 15

# Add nodes to cluster A
kubectl exec -ti vault-1 -- vault operator raft join http://vault-0.vault-internal:8200
kubectl exec -ti vault-1 -- vault operator unseal $VAULT_UNSEAL_KEY_CLUSTER_A
kubectl exec -ti vault-2 -- vault operator raft join http://vault-0.vault-internal:8200
kubectl exec -ti vault-2 -- vault operator unseal $VAULT_UNSEAL_KEY_CLUSTER_A

echo 'INFO: Nodes added to cluster A'

# Configure cluster B
kubectl exec vault-3 -- vault operator init -key-shares=1 -key-threshold=1 -format=json > cluster-b-keys.json
sleep 30

echo 'INFO: vault-3 initialized'

# Unseal vault-3
VAULT_UNSEAL_KEY_CLUSTER_B=$(jq -r ".unseal_keys_b64[]" cluster-b-keys.json)
kubectl exec vault-3 -- vault operator unseal $VAULT_UNSEAL_KEY_CLUSTER_B

echo 'INFO: Unsealed vault-3'
sleep 15

# Add nodes to cluster B
kubectl exec -ti vault-4 -- vault operator raft join http://vault-3.vault-internal:8200
kubectl exec -ti vault-4 -- vault operator unseal $VAULT_UNSEAL_KEY_CLUSTER_B
kubectl exec -ti vault-5 -- vault operator raft join http://vault-3.vault-internal:8200
kubectl exec -ti vault-5 -- vault operator unseal $VAULT_UNSEAL_KEY_CLUSTER_B

echo 'INFO: Nodes added to cluster B'

echo 'INFO: Raft cluster complete!'