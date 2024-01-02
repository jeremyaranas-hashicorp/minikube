# #!/usr/bin/env bash

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

# References https://developer.hashicorp.com/vault/docs/auth/ldap#scenario-3

# Enable LDAP auth method
kubectl exec -ti -n vault vault-0 -- vault auth enable -path=ldap ldap

# Write LDAP auth method config
kubectl exec -ti -n vault vault-0 -- vault write auth/ldap/config \
    url="ldap://openldap-auth-method.default.svc.cluster.local:1389" \
    userdn="ou=users,dc=example,dc=org" \
    groupdn="ou=users,dc=example,dc=org" \
    binddn="cn=admin,dc=example,dc=org" \
    userattr="uid" \
    bindpass="adminpassword" \
    starttls=false

# Deploy Alpine pod and install openldap-clients to perform to use LDAP utilities such as LDAP search
# This is for testing

# ./application_pod.sh
# apk update
# apk add openldap-clients
# ldapsearch -x -H ldap://openldap.default.svc.cluster.local:1389 -b dc=example,dc=org -D "cn=admin,dc=example,dc=org" -w adminpassword