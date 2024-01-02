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

# Enable LDAP secrets engine
kubectl exec -ti -n vault vault-0 -- vault secrets enable ldap

# Write LDAP secrets engine config 
kubectl exec -ti -n vault vault-0 -- vault write ldap/config \
    binddn="cn=admin,dc=example,dc=org" \
    bindpass=adminpassword \
    url="ldap://openldap-secrets-engine.default.svc.cluster.local:1389"

# Create static role
kubectl exec -ti -n vault vault-0 -- vault write ldap/static-role/hashicorp-ldap \
    dn='cn=user01,ou=users,dc=example,dc=org' \
    username='user01' \
    rotation_period="24h"

# Deploy Alpine pod and install openldap-clients to perform to use LDAP utilities such as LDAP search
# This is for testing

# ./application_pod.sh
# apk update
# apk add openldap-clients
# ldapsearch -x -H ldap://openldap.default.svc.cluster.local:1389 -b dc=example,dc=org -D "cn=admin,dc=example,dc=org" -w adminpassword