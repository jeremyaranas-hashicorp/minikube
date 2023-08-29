#!/usr/bin/env bash

# Uninstall Vault Helm chart
helm uninstall vault
helm uninstall vault-secondary

# Remove PVCs
kubectl delete pvc -l app.kubernetes.io/instance=vault 
kubectl delete pvc -l app.kubernetes.io/instance=vault-secondary 


# Remove files
rm -f init*.json
rm -f sat.txt

# Remove license
kubectl delete secrets vault-ent-license