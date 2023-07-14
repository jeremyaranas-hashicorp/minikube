## Enabling Replication (PR)

* Run replication script to enable replication and generate secondary activation token on primary, and enable replication on secondary
  * Run `./enable_pr.sh` from replication directory
* Check replication status
  * `kubectl exec -ti vault-0 -- vault read sys/replication/status -format=json`
  * `kubectl exec -ti vault-3 -- vault read sys/replication/status -format=json`
