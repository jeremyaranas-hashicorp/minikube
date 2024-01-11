#!/usr/bin/env bash

./vault_agent.sh
./postgresql_app_pod_v1.sh

# Wait for postgres pod to start
echo 'INFO: Waiting for Postgres container to start'
while [[ $(kubectl get po postgres -o json | jq -r .status.phase) != Running* ]]; 
do
sleep 1
done

source ../main/common.sh
write_database_config
write_database_role

# Create roles in postgres pod
kubectl exec -ti postgres -- psql -U root -c "CREATE ROLE \"ro\" NOINHERIT;"
kubectl exec -ti postgres -- psql -U root -c "GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"ro\";"

# Update Kubernetes auth method config to work with sample application pod
write_k8s_auth_config

# Deploy sample application pod
./sample_app.sh