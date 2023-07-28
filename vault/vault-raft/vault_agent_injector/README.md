# Vault Agent Injector

1. Run script to deploy Vault, setup k8s auth, and deploy application
   1. `./setup_vai.sh`
2. Confirm that secret was injected to app pod
   1. `kubectl exec -ti <app_pod> -- cat /vault/secrets/password.txt`

* Run cleanup script
  * `./cleanup.sh`

References: 

https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-sidecar

