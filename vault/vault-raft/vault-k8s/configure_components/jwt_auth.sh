#!/usr/bin/env bash

# This script will configure JWT auth using k8s as an OIDC provider

# Login to Vault
source ../main/common.sh
login_to_vault

kubectl create clusterrolebinding oidc-reviewer  \
   --clusterrole=system:service-account-issuer-discovery \
   --group=system:unauthenticated

ISSUER="$(kubectl get --raw /.well-known/openid-configuration | jq -r '.issuer')"

kubectl exec -n vault vault-0 -- vault auth enable jwt
kubectl exec -n vault vault-0 -- vault write auth/jwt/config \
   oidc_discovery_url=https://kubernetes.default.svc.cluster.local \
   oidc_discovery_ca_pem=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt

kubectl create token default | cut -f2 -d. | base64 --decode

kubectl exec -ti -n vault vault-0 -- vault write auth/jwt/role/test-role \
   role_type="jwt" \
   bound_audiences="https://kubernetes.default.svc.cluster.local" \
   user_claim="sub" \
   # bound_subject="system:serviceaccount:<namespace>:<service_account>" \
   bound_subject="system:serviceaccount:vault:vault" \
   policies="test-policy" \
   ttl="1h"

kubectl exec -ti -n vault vault-0 -- vault write auth/jwt/login \
   role=test-role \
   jwt=@/var/run/secrets/kubernetes.io/serviceaccount/token