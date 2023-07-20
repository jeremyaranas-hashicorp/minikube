## Vault Agent Injector

From `vault-raft` directory

1. Install Vault Helm chart
   1. helm install vault hashicorp/vault --values vault-values.yaml --set "server.ha.replicas=3"
2. Initialize Vault cluster
   1. ./init.sh

From to `vault_agent_injector` directory

1. Enable k8s auth method
   1. ./create_kv_secret.sh
   2. ./enable_k8s_auth.sh
2. Deploy app pod
   1. kubectl apply --filename deployment-orgchart.yaml
3. Test k8s auth from vault-0 pod 
   1. VAULT_JWT=$(k exec -ti vault-0 -- cat /var/run/secrets/kubernetes.io/serviceaccount/token)
   2. kubectl exec -ti vault-0 -- curl --request POST --data '{"jwt": "'$VAULT_JWT'", "role": "internal-app"}' http://127.0.0.1:8200/v1/auth/kubernetes/login
4. Test k8s auth from orgchart app pod
   1. APP_JWT=$(k exec -ti <app_pod> -- cat /var/run/secrets/kubernetes.io/serviceaccount/token)
   2. kubectl exec -ti <app_pod> -- curl --request POST --data '{"jwt": "'$APP_JWT'", "role": "internal-app"}' http://127.0.0.1:8200/v1/auth/kubernetes/login
5. Confirm that secret was injected to app pod
   1. k exec -ti orgchart-7ff647d464-nk8mh -- cat /vault/secrets/database-config.txt

References: 

https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-sidecar


