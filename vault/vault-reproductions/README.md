This repo spins up a Vault Raft cluster in k8s using the Vault Helm chart

# Prerequisites

* `jq`
* `kubectl`
* `minikube`
* `VAULT_LICENSE` env variable (add to bashrc or zshrc)
* `kubectl` shortcut (optional)
  * Add to bashrc or zshrc
    * `alias k=kubectl`
    * `complete -o default -F __start_kubectl k`

# Instructions

See **instructions** directory

### Add the following to the instructions directory

1. Start Minikube
   1. `minikube start`
2. Initialize primary cluster
   1. `cd` to **setup** directory
   2. `./init-primary.sh`
3. Enable Vault Secrets Operator 
   1. `cd` to **configure_components** directory
   2. `./vault-secrets-operator.sh`
   3. Retrieve k8s secret
      1. `kubectl get secret -n vso secretkv -o jsonpath="{.data.password}" | base64 --decode`


1. Start Minikube
   1. `minikube start`
2. Initialize primary cluster
3. `cd` to **setup** directory
   1. `./init-primary.sh`
4. Enable CSI Provider
   1. `cd` to **configure_components** directory
   2. `./csi_provider.sh`
   3. Check that secret exist in app pod 
      1. `kubectl exec -n vault csi-app-pod -- cat /mnt/secrets-store/test-object`



1. Start Minikube
   1. `minikube start`
2. Initialize primary cluster
   1. `cd` to **setup** directory
   2. `./init-primary.sh`
3. Enable JWT auth method 
   1. `cd` to **configure_components** directory
   2. `./jwt_auth.sh`
4. Test login using JWT auth method
   1. `kubectl exec -ti -n vault vault-0 -- vault write auth/jwt/login role=test-role jwt=@/var/run/secrets/kubernetes.io/serviceaccount/token`

1. Start Minikube
   1. `minikube start`
2. Initialize primary cluster
   1. `cd` to **setup** directory
   2. `./init-primary.sh`
3. Enable Vault Agent Injector 
   1. `cd` to **configure_components** directory
   2. `./vault-agent.sh`
   3. Check that secret exists in postgres app pod 
      1. `kubectl exec -ti postgres-<pod> -- cat /vault/secrets/password.txt`
4. Configure Vault Agent with JWT auto-auth
   1. `./vault-agent-jwt-auto-auth.sh` 
   2. Check that config.json is rendered
      1. `kubectl exec -ti postgres-<pod> -c vault-agent -- sh`
      2. `cat /home/vault/config.json`
   
# Sources

* https://developer.hashicorp.com/vault/docs/platform/k8s/helm/examples/standalone-tls
* https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-minikube-tls#create-the-certificate

