# Update secret in Vault 
kubectl exec vault-0 -n vault -- vault kv put kvv2/test-vault-secret username="static-user-updated-2" password="static-password-updated-2"