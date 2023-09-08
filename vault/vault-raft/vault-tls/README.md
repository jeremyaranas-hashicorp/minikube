This repo spins up a Vault Raft cluster in k8s with TLS

Sources:

* https://developer.hashicorp.com/vault/docs/platform/k8s/helm/examples/standalone-tls
* https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-minikube-tls#create-the-certificate


1. Start Minikube
`minikube start`

2. Generate certificates
`./certs.sh`

3. Initialize primary Vault
`./init-primary.sh`

4. Initialize secondary cluster 
`./init-secondary.sh`


1. Confirm that cluster is using TLS
   1. `kubectl exec -ti vault-0 -n vault -- vault status`
      1. Note that HA cluster is pointing to https
   2. Log into pod and echo $VAULT_ADDR
      1. `kubectl exec -ti vault-0 -n vault -- /bin/sh`
         1. `echo $VAULT_ADDR`
            1. Note that address is using https
2. In another terminal window, forward port to view Vault in UI
   1. `kubectl -n vault port-forward service/vault 8200:8200`
      1. Go to `https://127.0.0.1:8200` using a browser to confirm Vault UI has HTTPS



* Make sure to run the cleanup.sh script to remove old certs when creating a new lab







