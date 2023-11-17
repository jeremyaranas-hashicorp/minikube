#!/usr/bin/env bash

source ../main/common.sh

kubectl exec -ti -n vault vault-0 -- vault secrets enable database 

kubectl apply -f ../manifests/postgres-db.yaml

# kubectl exec -ti -n vault vault-0 -- vault write database/config/postgresql plugin_name=postgresql-database-plugin connection_url="postgresql://{{username}}:{{password}}@10.244.0.8:5432/postgres?sslmode=disable" allowed_roles=readonly  username="root"  password="rootpassword"


# Create a file in /tmp called readonly.sql and add the statement
# CREATE ROLE "{{name}}" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}' INHERIT;
# GRANT ro TO "{{name}}";

# kubectl exec -ti -n vault vault-0 -- vault write database/roles/readonly \
#       db_name=postgresql \
#       creation_statements=@/tmp/readonly.sql \
#       default_ttl=1m \
#       max_ttl=1m



# kubectl exec -ti -n vault vault-0 -- vault write database/config/psql plugin_name=postgresql-database-plugin connection_url="postgresql://{{username}}:{{password}}@10.244.0.8:5432/postgres?sslmode=disable" allowed_roles="readonly"  username="root"  password="rootpassword"


# kubectl exec -ti postgres -- sh
# psql -U root -c "CREATE ROLE \"ro\" NOINHERIT;"
# psql -U root -c "CREATE ROLE \"ro\" NOINHERIT;"
# psql -U root -c "GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"ro\";"