# Login with root token
kubectl exec vault-0 -- vault login $(jq -r ".root_token" ../cluster-a-keys.json)
# Enable secrets engine
kubectl exec -ti vault-0 -- vault secrets enable -path=internal kv
# Add secret
kubectl exec -ti vault-0 -- vault kv put internal/database/config username="db-readonly-username" password="db-secret-password"

