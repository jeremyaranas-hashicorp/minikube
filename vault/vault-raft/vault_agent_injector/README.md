# Vault Agent Injector

1. Install Vault Helm chart
   1. `helm install vault hashicorp/vault --values vault-values.yaml`
2. Initialize Vault cluster
   1. `./init.sh`
3. Enable k8s auth method
   1. `./enable_vai.sh`
4. Deploy app pod
   1. `kubectl apply --filename nginx-deployment.yaml`
5. Test k8s auth from vault-0 pod 
   1. `VAULT_JWT=$(k exec -ti vault-0 -- cat /var/run/secrets/kubernetes.io/serviceaccount/token)`
   2. `kubectl exec -ti vault-0 -- curl --request POST --data '{"jwt": "'$VAULT_JWT'", "role": "internal-app"}' http://127.0.0.1:8200/v1/auth/kubernetes/login`
6. Test k8s auth from orgchart app pod (applicable if container has curl installed)
   1. `APP_JWT=$(k exec -ti <app_pod> -- cat /var/run/secrets/kubernetes.io/serviceaccount/token)`
   2. `kubectl exec -ti <app_pod> -- curl --request POST --data '{"jwt": "'$APP_JWT'", "role": "internal-app"}' http://127.0.0.1:8200/v1/auth/kubernetes/login`
7. Confirm that secret was injected to app pod
   1. `kubectl exec -ti <app_pod> -- cat /vault/secrets/password.txt`

* Run cleanup script
  * `./cleanup.sh`

References: 

https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-sidecar

