# Enabling Replication (PR) 

1. Start a new Minikube cluster
   1. `minikube start -p <cluster_name>`
2. Deploy Vault Helm and enable replication, generate secondary activation token on primary, and enable replication on secondary
   1. `./enable_pr.sh`
3. Check replication status
   1. `kubectl exec -ti vault-0 -- vault read sys/replication/status -format=json`
   2. `kubectl exec -ti vault-3 -- vault read sys/replication/status -format=json`

* Run cleanup script
  * `./cleanup.sh`
