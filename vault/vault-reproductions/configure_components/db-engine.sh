kubectl exec -ti -n vault vault-0 -- vault secrets enable database 

# kubectl exec -ti -n vault vault-0 -- vault write database/config/postgresql plugin_name=postgresql-database-plugin connection_url="postgresql://{{username}}:{{password}}@10.244.0.11:5432/postgres?sslmode=disable" allowed_roles=readonly  username="root"  password="rootpassword"

# kubectl exec -ti -n vault vault-0 -- vault write database/roles/readonly \
#       db_name=postgresql \
#       creation_statements=@readonly.sql \
#       default_ttl=1m \
#       max_ttl=1m


# kubectl exec -ti -n vault vault-0 -- vault write database/roles/readonly \
#       db_name=postgresql \
#       creation_statements=@readonly.sql \
#       default_ttl=1m \
#       max_ttl=1m