# Enabling Replication (PR) 

1. Install Vault Helm chart
   1. `helm install vault hashicorp/vault --values vault-values.yaml`
2. Initialize Vault cluster
   1. `./init.sh`
3. Run replication script to enable replication, generate secondary activation token on primary, and enable replication on secondary
   1. `./enable_pr.sh`
4. Check replication status
   1. `kubectl exec -ti vault-0 -- vault read sys/replication/status -format=json`
   2. `kubectl exec -ti vault-3 -- vault read sys/replication/status -format=json`

* Run cleanup script
  * `./cleanup.sh`
