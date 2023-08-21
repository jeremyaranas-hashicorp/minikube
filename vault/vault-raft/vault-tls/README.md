This repo spins up a Vault node in k8s with TLS

1. Start Minikube
`minikube start`

2. Run 
`./certs.sh`

3. Init clusters
`./init.sh`

4. Login to vault-0
`kubectl exec --stdin=true --tty=true vault-0 -n vault -- /bin/sh`

5. Run
`vault status`
`echo $VAULT_ADDR`

6. Add other nodes to the cluster (need to set up retry_join)
   1. `k exec -ti vault-1 -n vault -- vault operator raft join -leader-ca-cert="@/vault/userconfig/vault-server-tls/vault.ca" "https://vault-0.vault-internal:8200"`
   2. `k exec -ti vault-1 -n vault -- vault operator unseal`
   3. `k exec -ti vault-2 -n vault -- vault operator raft join -leader-ca-cert="@/vault/userconfig/vault-server-tls/vault.ca" "https://vault-0.vault-internal:8200"`
   4. `k exec -ti vault-2 -n vault -- vault operator unseal`

7. In another terminal window, forward port to view Vault in UI

`kubectl port-forward vault-0 -n vault 8200:8200`

1. Go to `https://127.0.0.1:8200` using a browser to confirm Vault UI has HTTPS



