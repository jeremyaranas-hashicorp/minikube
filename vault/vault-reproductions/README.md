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

1. Enable Vault Secrets Operator 
   1. `./vault-secrets-operator.sh`
   2. Retrieve k8s secret
      1. `kubectl get secret -n vso secretkv -o jsonpath="{.data.password}" | base64 --decode`
2. Enable CSI Provider
   1. `./csi_provider.sh`
   2. Check that secret exist in app pod 
      1. `kubectl exec -n vault csi-app-pod -- cat /mnt/secrets-store/test-object`
3. Enable JWT auth method 
   1. `./jwt_auth.sh`
   2. Test login using JWT auth method
      1. `kubectl exec -ti -n vault vault-0 -- vault write auth/jwt/login role=test-role jwt=@/var/run/secrets/kubernetes.io/serviceaccount/token`
4. Enable Vault Agent Injector 
   1. `./vault-agent.sh`
   2. Check that secret exists in postgres app pod 
      1. `kubectl exec -ti postgres-<pod> -- cat /vault/secrets/password.txt`
   3. Configure Vault Agent with JWT auto-auth
      1. `./vault-agent-jwt-auto-auth.sh` 
      2. Check that config.json is rendered
         1. `kubectl exec -ti postgres-<pod> -c vault-agent -- sh`
         2. `cat /home/vault/config.json`
   
# Sources

* https://developer.hashicorp.com/vault/docs/platform/k8s/helm/examples/standalone-tls
* https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-minikube-tls#create-the-certificate

