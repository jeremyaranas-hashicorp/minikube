#!/usr/bin/env bash

source ../main/common.sh
./k8s_auth.sh
configure_test_secrets_engine
enable_k8s_auth
set_vault_policy
configure_k8s_auth_role

helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts
helm install -n vault csi secrets-store-csi-driver/secrets-store-csi-driver \
    --set syncSecret.enabled=true

kubectl apply --filename ../manifests/csi-secret-provider-class.yaml
kubectl apply --filename ../manifests/csi-app-pod.yaml