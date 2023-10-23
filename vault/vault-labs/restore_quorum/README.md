This lab will review how to restore quorum in a Raft cluster running in k8s 

1. Set `VAULT_LICENSE` environment variable 
2. Deploy a Vault cluster with 3 replicas
   1. Go to vault-ha-tls-raft-cluster directory
   2. Follow steps 1-3 in README.md

# Lab

1. Once the cluster is up with 3 pods, scale the replicas to 1 to cause Raft to lose quorum
   1. `kubectl scale statefulsets -n vault vault --replicas=1`
2. The remaining vault-0 pod should become a standby
   1. `kubectl exec -ti -n vault vault-0 -- vault status`
3. Exec into the the vault-0 pod
   1. `kubectl exec -ti -n vault vault-0 -- /bin/sh` 
4. Run `ps -ef` to find the location to the storageconfig.hcl
5. `cat /tmp/storageconfig.hcl` to find raft directory
6. cd to the raft directory
   1. `cd /vault/data/raft`
7. Run `env | grep -i VAULT_CLUSTER_ADDR` and save the address. This address will be used in the peers.json file. 
8. Create the peers.json in the raft directory 
   1. `vi peers.json`

```
# Update id and address
[
  {
    "id": "<node_id>",
    "address": "<VAULT_CLUSTER_ADDR>:8201",
    "non_voter": false
  }
]

# Example
[
  {
    "id": "vault-0",
    "address": "vault-0.vault-internal.vault.svc.cluster.local:8201",
    "non_voter": false
  }
]
```

9. Update node-id to match id in peers.json
   1.  `vi /vault/data/node-id`
10. Exit vault-0 pod
11. Edit configmap to add node_id
    1.  `kubectl edit configmap -n vault vault-config`
    2.  Add `node_id = "<node_id>"` to Raft storage stanza
12. Delete vault-0 to reschedule pod
    1.  `kubectl delete pod -n vault vault-0`
13. Unseal vault-0
    1.  `export VAULT_UNSEAL_KEY=$(jq -r ".unseal_keys_b64[]" init.json)`
    2.  `kubectl exec -ti -n vault vault-0  -- vault operator unseal $VAULT_UNSEAL_KEY`
14. vault-0 should be active
    1.  `kubectl exec -ti -n vault vault-0 -- vault status`
15. Edit configmap to remove node_id
    1.  `kubectl edit configmap -n vault vault-config`
    2.  Remove `node_id = "<node_id>"` from Raft storage stanza
16. Scale pods up to 3
    1.  `kubectl scale statefulsets -n vault vault --replicas=3`
17. Exec into vault-1
    1.  `kubectl exec -ti -n vault vault-1 -- /bin/sh`
18. Remove raft directory and vault.db
    1.  `rm -fr /vault/data/raft /vault/data/vault.db`
19. Rename node-id to vault-1
    1.  `vi /vault/data/node-id`
20. Exit vault-1 pod 
21. Delete vault-1 to reschedule
    1.  `kubectl delete pod -n vault vault-1`
22. Init, unseal and join vault-1 to cluster
    1.  `kubectl exec -ti -n vault vault-1 -- vault operator unseal $VAULT_UNSEAL_KEY`
23. Login to Vault
    1.  `source ./common.sh`
    2.  `login_to_vault`
24. Confirm that nodes joined cluster
    1.  `kubectl exec -ti -n vault vault-0 -- vault operator raft list-peers`
25. Repeat steps 17-22 for each additional standby node

```
➜  vault-ha-tls-raft-cluster git:(main) ✗ k logs -n vault vault-0 | grep recovery
2023-09-19T19:59:39.451Z [INFO]  storage.raft: raft recovery initiated: recovery_file=peers.json
2023-09-19T19:59:39.451Z [INFO]  storage.raft: raft recovery found new config: config="{[{Voter vault-0 vault-0.vault-internal.vault.svc.cluster.local:8201}]}"
2023-09-19T19:59:39.454Z [INFO]  storage.raft: raft recovery deleted peers.json
2023-09-19T19:59:39.507Z [INFO]  replication.index.perf: checkpoint recovery complete
```