#!/usr/bin/env bash

source ../main/common.sh
login_to_vault
create_test_sa_resources
create_clusterrolebinding_for_k8s_auth
enable_k8s_auth

KUBE_CA_CERT=$(kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.certificate-authority-data}' | base64 --decode)
KUBE_HOST=$(kubectl exec -ti -n vault vault-0 -- env | grep KUBERNETES_SERVICE_HOST | cut -d "=" -f2)

configure_k8s_auth
set_vault_policy
configure_test_secrets_engine
configure_k8s_auth_role
  
# Reference https://support.hashicorp.com/hc/en-us/articles/4404389946387