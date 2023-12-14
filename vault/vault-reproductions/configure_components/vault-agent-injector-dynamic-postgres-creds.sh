# Deploy Vault Agent
./vault-agent.sh

# Deploy Postgres pod
./postgresql-app-pod-01.sh

# Wait for Postgres pod to start, then export IP of pod
echo 'INFO: Waiting for Postgres container to start'
while [[ $(kubectl get po postgres -o json | jq -r .status.phase) != Running* ]]; 
do
sleep 1
done
export PG_IP=$(kubectl get pod postgres --template '{{.status.podIP}}')

# Write database config
kubectl exec -ti -n vault vault-0 -- vault write database/config/postgresql plugin_name=postgresql-database-plugin connection_url="postgresql://{{username}}:{{password}}@$PG_IP:5432/postgres?sslmode=disable" allowed_roles=readonly username="root"  password="rootpassword"

# Write role for database config
kubectl exec -ti -n vault vault-0 -- vault write database/roles/readonly \
    db_name="postgresql" \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
        GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
    default_ttl="1m" \
    max_ttl="1m"

# Create roles in Postgres pod
kubectl exec -ti postgres -- psql -U root -c "CREATE ROLE \"ro\" NOINHERIT;"
kubectl exec -ti postgres -- psql -U root -c "GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"ro\";"

# Update Kubernetes auth method config to work with sample application pod
kubectl exec -ti -n vault vault-0 -- vault write auth/kubernetes/config kubernetes_host="https://10.96.0.1:443"

# Deploy sample application
./sample_app.sh