# Vault license must be set using the VAULT_LICENSE environment variable
# export VAULT_LICENSE="<license_string>"
secret=$VAULT_LICENSE
# Create k8s secret for Vault license
kubectl create secret generic vault-ent-license --from-literal="license=${secret}"

echo 'INFO: Starting Raft cluster setup'
sleep 15

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

echo 'INFO: Raft cluster complete!'