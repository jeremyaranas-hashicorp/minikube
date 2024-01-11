#!/usr/bin/env bash

source ../main/common.sh
login_to_vault

# Create secret for OpenLDAP
kubectl create secret generic openldap-secrets-engine --from-literal=adminpassword=adminpassword --from-literal=users=user01,user02 --from-literal=passwords=password01,password02

# Deploy OpenLDAP container
kubectl apply -f ../manifests/ldap-deployment-secrets-engine.yaml

# Wait for OpenLDAP container to start
while [[ $(kubectl get pods -l app.kubernetes.io/name=openldap-secrets-engine -o jsonpath='{.items[*].status.containerStatuses[0].started}') != true* ]]; 
    do
    sleep 1
    echo 'INFO: Waiting for OpenLDAP container to start'
    done
    echo 'INFO: OpenLDAP container started'
    sleep 5

enable_ldap_secrets_engine
write_ldap_secrets_engine_config
create_ldap_secrets_engine_static_role

