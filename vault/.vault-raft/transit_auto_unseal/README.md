# Vault Kubernetes Cluster

1. Start a new Minikube cluster
   1. `minikube start -p <cluster_name>`
2. Deploy Transit
   1. `./transit-init.sh`
2. Get `client_token` from token.json and update `token` in seal stanza in vault-values.yaml 
3. Deploy Vault
   1. `./vault-init.sh`


* Run cleanup script
  * `./cleanup.sh`

