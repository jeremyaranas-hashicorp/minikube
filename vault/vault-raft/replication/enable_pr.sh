# Log into vault-0
kubectl exec vault-0 -- vault login $(jq -r ".root_token" ../cluster-a-keys.json)
# Enable replication on primary
kubectl exec -ti vault-0 -- vault write -f sys/replication/performance/primary/enable
# Genrerate secondary activation token
kubectl exec -ti vault-0 -- vault write sys/replication/performance/primary/secondary-token id=pr_secondary -format=json | jq -r .wrap_info.token > sat.txt
# Log into vault-3
kubectl exec vault-3 -- vault login $(jq -r ".root_token" ../cluster-b-keys.json)
# Enable replication on secondary
kubectl exec -ti vault-3 -- vault write sys/replication/performance/secondary/enable token=$(cat sat.txt)