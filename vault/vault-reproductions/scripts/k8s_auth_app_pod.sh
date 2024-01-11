#!/usr/bin/env bash

# With disable_local_ca_jwt=false

source ../main/common.sh
./k8s_auth.sh
../setup/application_pod.sh
write_k8s_auth_config

# With disable_local_ca_jwt=true

# Manual steps 

# Get CA cert from app pod
# kubectl exec -ti -n vault alpine -- cat /var/run/secrets/kubernetes.io/serviceaccount/ca.crt

# Create file in Vault pod for ca.crt, copy ca.crt contents from app pod, paste ca.crt contents from app pod to Vault pod
# kubectl exec -ti -n vault vault-0 -- sh
# vi /tmp/ca.crt
# Exit Vault pod

# Get service account JWT
# SA_JWT=$(kubectl get secret -n vault test-secret -o go-template='{{ .data.token }}' | base64 --decode)

# Write k8s auth method config
# kubectl exec -ti -n vault vault-0 -- vault write auth/kubernetes/config kubernetes_host="https://10.96.0.1:443" disable_local_ca_jwt=true kubernetes_ca_cert=@/tmp/ca.crt token_reviewer_jwt=$SA_JWT

# Export app pod local JWT
# APP_POD_LOCAL_JWT=$(kubectl exec -ti -n vault alpine -- cat /var/run/secrets/kubernetes.io/serviceaccount/token)

# Authenticate from app pod to Vault
# kubectl exec -ti -n vault alpine -- curl -k --request POST --data '{"jwt": "'$APP_POD_LOCAL_JWT'", "role": "test-role"}' http://vault-active.vault.svc.cluster.local:8200/v1/auth/kubernetes/login