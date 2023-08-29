# Enabling Replication (PR) 

1. Start a new Minikube cluster
   1. `minikube start -p <cluster_name>`
2. Deploy Vault Helm and enable replication, generate secondary activation token on primary, and enable replication on secondary
   1. `./enable_pr.sh`
3. Check replication status
   1. `kubectl exec -ti vault-0 -- vault read sys/replication/status -format=json`



# Readiness and Liveness Probes 

1. Once the clusters are up and replication has been enabled, update the readiness and liveness probes to `enabled: true` in vault-values.yaml and vault-values-secondary.yaml
2. Upgrade the Helm charts
   1. `helm upgrade vault hashicorp/vault --values vault-values.yaml`
   2. `helm upgrade vault-secondary hashicorp/vault --values vault-values-secondary.yaml`
3. Delete each pod to reschedule pod and unseal each pod using the unseal keys from the primary
   1. `kubectl delete pod <pod>`
   2. `export VAULT_UNSEAL_KEY=$(jq -r ".unseal_keys_b64[]" init.json)`
   3. `kubectl exec -ti <pod> -- vault operator unseal $VAULT_UNSEAL_KEY`



* Run cleanup script
  * `./cleanup.sh`