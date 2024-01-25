#!/usr/bin/env bash

# Create secret for OpenLDAP
kubectl create secret generic openldap-auth-method --from-literal=adminpassword=adminpassword --from-literal=users=user01,user02 --from-literal=passwords=password01,password02

# Deploy OpenLDAP container
kubectl apply -f ../manifests/ldap-deployment-auth-method.yaml

# Wait for OpenLDAP container to start
while [[ $(kubectl get pods -l app.kubernetes.io/name=openldap-auth-method -o jsonpath='{.items[*].status.containerStatuses[0].started}') != true* ]]; 
    do
    sleep 1
    echo 'INFO: Waiting for OpenLDAP container to start'
    done
    echo 'INFO: OpenLDAP container started'
    sleep 5

source ../main/common.sh
enable_ldap_auth
write_ldap_auth_config

# Reference https://developer.hashicorp.com/vault/docs/auth/ldap#scenario-3
