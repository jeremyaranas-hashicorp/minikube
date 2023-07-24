# Update secret in Vault 
kubectl exec vault-0 -n vault -- vault kv put kvv2/webapp/config username="static-user-updated" password="static-password-updated"