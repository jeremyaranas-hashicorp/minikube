source ../common.sh
install_vault_helm
set_ent_license
init_vault
unseal_vault
add_nodes_to_cluster
init_vault_2
unseal_vault_2
add_nodes_to_cluster_2
login_to_vault

# Enable replication on primary
kubectl exec -ti vault-0 -- vault write -f sys/replication/performance/primary/enable

# Genrerate secondary activation token
kubectl exec -ti vault-0 -- vault write sys/replication/performance/primary/secondary-token id=pr_secondary -format=json | jq -r .wrap_info.token > sat.txt

# Log into vault-3
source ../common.sh
login_to_vault_2

# Enable replication on secondary
kubectl exec -ti vault-3 -- vault write sys/replication/performance/secondary/enable token=$(cat sat.txt)