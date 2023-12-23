# #!/usr/bin/env bash

# LDAP secrets engine

helm repo add helm-openldap https://jp-gouin.github.io/helm-openldap/
helm install ldap helm-openldap/openldap-stack-ha

kubectl exec -ti -n vault vault-0 -- vault secrets enable ldap

kubectl exec -ti -n vault vault-0 -- vault write ldap/config \
    binddn="cn=admin,dc=example,dc=org" \
    bindpass=Not@SecurePassw0rd \
    url=ldap://ldap.default.svc.cluster.local

# Create static role

kubectl exec -ti -n vault vault-0 -- vault write ldap/static-role/hashicorp-ldap \
    dn='cn=user01,ou=users,dc=example,dc=org' \
    username='user01' \
    rotation_period="24h"

kubectl exec -ti -n vault vault-0 -- vault read ldap/static-cred/hashicorp-ldap

# LDAP auth method 

kubectl apply -f ../manifests/ldap-pod.yaml

kubectl create secret generic openldap --from-literal=adminpassword=adminpassword --from-literal=users=user01,user02 --from-literal=passwords=password01,password02

# References https://developer.hashicorp.com/vault/docs/auth/ldap#scenario-3

kubectl exec -ti -n vault vault-0 -- vault auth enable -path=ldap-2 ldap

kubectl exec -ti -n vault vault-0 -- vault write auth/ldap-2/config \
    url="ldap://openldap.default.svc.cluster.local:1389" \
    userdn="ou=users,dc=example,dc=org" \
    groupdn="ou=users,dc=example,dc=org" \
    binddn="cn=admin,dc=example,dc=org" \
    userattr="uid" \
    bindpass="adminpassword" \
    starttls=false

kubectl exec -ti -n vault vault-0 -- vault login -method=ldap -path=ldap-2 username="user01" password=password01


# Deploy Alpine pod and install openldap-clients to perform to use LDAP utilities such as LDAP search
# This is for testing

# ./application_pod.sh
# apk update
# apk add openldap-clients
# ldapsearch -x -H ldap://openldap.default.svc.cluster.local:1389 -b dc=example,dc=org -D "cn=admin,dc=example,dc=org" -w adminpassword