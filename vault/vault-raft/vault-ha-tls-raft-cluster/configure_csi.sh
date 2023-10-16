#!/usr/bin/env bash

source ./common.sh
login_to_vault
configure_secrets_engine
configure_k8s_auth
set_vault_policy
configure_k8s_auth_role

# Install secrets store CSI driver
helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts
helm install -n vault csi secrets-store-csi-driver/secrets-store-csi-driver \
    --set syncSecret.enabled=true

# Create the SecretProviderClass
kubectl apply --filename test-secretproviderclass.yaml

# Create application pod
kubectl apply --filename app-pod.yaml