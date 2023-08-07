#!/usr/bin/env bash

# Uninstall Helm charts
helm uninstall vault
helm uninstall csi

# Remove PVCs
kubectl delete pvc -l app.kubernetes.io/instance=vault 

# Remove files
rm -f init.json

# Remove license
kubectl delete secrets vault-ent-license

# Remove sa
kubectl delete sa test-sa

# Remove secret provider class
kubectl delete secretproviderclass test-secretproviderclass