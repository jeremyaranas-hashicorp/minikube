#!/usr/bin/env bash

source ../main/common.sh

./k8s_auth.sh
write_k8s_auth_config

helm install vault-secrets-operator hashicorp/vault-secrets-operator -n vault-secrets-operator-system --create-namespace --values ../helm-chart-values-files/vault-operator-values.yaml

kubectl create ns vso

kubectl apply -f ../manifests/vso-custom-resources-tls.yaml
