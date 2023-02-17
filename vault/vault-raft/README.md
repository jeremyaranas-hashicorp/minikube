This repo spins up a Vault primary and secondary Raft cluster

# Preqrequisites

* minikube

# Start Minikube

1. Start Minikube

`minikube start`

# Deploy [Vault](https://developer.hashicorp.com/vault/docs/platform/k8s/helm/examples/ha-with-raft) Nodes

1. Add license to k8s secret (Vault license should be exported as local environment variable)

```
secret=$VAULT_LICENSE
kubectl create secret generic vault-ent-license --from-literal="license=${secret}"
```

2. Install Vault

`helm install vault hashicorp/vault --values vault-values.yml`

3. Init clusters
`./init.sh`

4. Login to vault-0
`kubectl exec --stdin=true --tty=true vault-0 -- /bin/sh`

5. Login to vault-3
`kubectl exec --stdin=true --tty=true vault-3 -- /bin/sh`

