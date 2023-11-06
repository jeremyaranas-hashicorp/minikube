#!/usr/bin/env bash

source ../main/common.sh
login_to_vault
configure_test_secrets_engine
configure_k8s_auth
set_vault_policy
configure_k8s_auth_role

# Install secrets store CSI driver
helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts
helm install -n vault csi secrets-store-csi-driver/secrets-store-csi-driver \
    --set syncSecret.enabled=true

# Create the SecretProviderClass
kubectl apply --filename ../manifests/test-secretproviderclass.yaml

# Create application pod
kubectl apply --filename ../manifests/nginx.yaml
