Initialize and unseal Vault clusters by installing Helm chart and running `./init.sh`.

1. ./create_kvv2_secret
2. ./enable_k8s_auth
3. Deploy app pod
   1. kubectl apply --filename deployment-orgchart.yaml
4. Test k8s auth from vault-0 pod 
   1. VAULT_JWT=$(k exec -ti vault-0 -- cat /var/run/secrets/kubernetes.io/serviceaccount/token)
   2. kubectl exec -ti vault-0 -- curl --request POST --data '{"jwt": "'$VAULT_JWT'", "role": "internal-app"}' http://127.0.0.1:8200/v1/auth/kubernetes/login
5. Test k8s auth from orgchart app pod
   1. APP_JWT=$(k exec -ti <app_pod> -- cat /var/run/secrets/kubernetes.io/serviceaccount/token)
   2. kubectl exec -ti <app_pod> -- curl --request POST --data '{"jwt": "'$APP_JWT'", "role": "internal-app"}' http://127.0.0.1:8200/v1/auth/kubernetes/login




References: 

https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-sidecar


