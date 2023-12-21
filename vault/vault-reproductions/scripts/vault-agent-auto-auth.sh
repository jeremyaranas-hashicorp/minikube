#!/usr/bin/env bash

# This script will configure JWT auth using k8s as an OIDC provider

# Reference https://developer.hashicorp.com/vault/docs/auth/jwt/oidc-providers/kubernetes

# Login to Vault
source ../main/common.sh
create_test_sa_resources

# Ensure OIDC discovery URLs 
kubectl create clusterrolebinding oidc-reviewer  \
   --clusterrole=system:service-account-issuer-discovery \
   --group=system:unauthenticated

# Find the issuer URL
ISSUER="$(kubectl get --raw /.well-known/openid-configuration | jq -r '.issuer')"

# Enable and configure JWT auth for Vault running in k8s
kubectl exec -n vault vault-0 -- vault auth enable jwt
kubectl exec -n vault vault-0 -- vault write auth/jwt/config \
   oidc_discovery_url=https://kubernetes.default.svc.cluster.local \
   oidc_discovery_ca_pem=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt

# Find default audience
kubectl create token default | cut -f2 -d. | base64 --decode

# Create role for JWT auth for app pod
kubectl exec -ti -n vault vault-0 -- vault write auth/jwt/role/test-role \
   role_type="jwt" \
   bound_audiences="https://kubernetes.default.svc.cluster.local" \
   user_claim="sub" \
   bound_subject="system:serviceaccount:default:postgres-service-account" \
   policies="test-policy" \
   ttl="1h"