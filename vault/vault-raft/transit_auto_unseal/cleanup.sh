#!/usr/bin/env bash

# Uninstall Vault Helm chart
helm uninstall vault
helm uninstall vault-auto-unseal

# Remove PVCs
kubectl delete pvc -l app.kubernetes.io/instance=vault 
kubectl delete pvc -l app.kubernetes.io/instance=vault-auto-unseal



# Remove files
rm -f init.json
rm -f init-auto-unseal.json
rm -f token.json

# Remove license
kubectl delete secrets vault-ent-license