# Vault Agent Injector

1. Start a new Minikube cluster
   1. `minikube start -p <cluster_name>`
2. Deploy Vault Helm, set up Vault Agent Injector
   1. `./setup_vai.sh`
3. Confirm that secret was injected to app pod
   1. `kubectl exec -ti <app_pod> -- cat /vault/secrets/password.txt`

* Run cleanup script
  * `./cleanup.sh`

References: 

https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-sidecar

