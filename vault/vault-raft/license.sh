# Vault license must be set using the VAULT_LICENSE environment variable
# export VAULT_LICENSE="<license_string>"
secret=$VAULT_LICENSE
# Create k8s secret for Vault license
kubectl create secret generic vault-ent-license --from-literal="license=${secret}"