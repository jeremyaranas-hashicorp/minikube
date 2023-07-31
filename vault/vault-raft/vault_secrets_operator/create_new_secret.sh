# Update secret in Vault 
kubectl exec vault-0 -n vault -- vault kv put test/secret username="static-username-updated" password="static-password-updated"