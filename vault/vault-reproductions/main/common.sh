#!/usr/bin/env bash

enable_performance_replication () {
    login_to_vault
    kubectl exec -ti -n vault vault-0 -- vault read sys/replication/status -format=json | jq .data.performance.mode | grep -q primary
    if [ $? -eq 0 ] 
    then 
        echo "INFO: Performance replication is already configured" 
    else 
        echo "INFO: Enabling performance replication" 
        kubectl exec -ti -n vault vault-0 -- vault write -f sys/replication/performance/primary/enable
        kubectl exec -ti -n vault vault-0 -- vault write sys/replication/performance/primary/secondary-token id="secondary" -format=json  | jq -r .wrap_info.token > sat.txt
        login_to_vault_secondary
        kubectl exec -ti -n vault-secondary vault-secondary-0 -- vault write sys/replication/performance/secondary/enable token=$(cat sat.txt) 
    fi
}

enable_performance_replication_tls () {
    login_to_vault
    kubectl exec -ti -n vault vault-0 -- vault read sys/replication/status -format=json | jq .data.performance.mode | grep -q primary
    if [ $? -eq 0 ] 
    then 
        echo "INFO: Performance replication is already configured" 
    else 
        echo "INFO: Enabling performance replication" 
        kubectl exec -ti -n vault vault-0 -- vault write -f sys/replication/performance/primary/enable
        kubectl exec -ti -n vault vault-0 -- vault write sys/replication/performance/primary/secondary-token id="secondary" -format=json  | jq -r .wrap_info.token > sat.txt
        login_to_vault_secondary
        kubectl exec -ti -n vault-secondary vault-secondary-0 -- vault write sys/replication/performance/secondary/enable token=$(cat sat.txt) ca_file=/vault/vault-tls/vault.ca
    fi
}

enable_audit_device () {
    login_to_vault
    kubectl exec -ti -n vault vault-0 -- touch /vault/audit/audit.log
    kubectl exec -ti -n vault vault-0 -- chown vault:vault /vault/audit/audit.log
    kubectl exec -ti -n vault vault-0 -- vault audit enable file file_path=/vault/audit/audit.log
}

enable_audit_device_secondary () {
    login_to_vault_secondary
    kubectl exec -ti -n vault-secondary vault-secondary-0 -- mkdir -p /vault/audit
    kubectl exec -ti -n vault-secondary vault-secondary-0 -- touch /vault/audit/audit.log
    kubectl exec -ti -n vault-secondary vault-secondary-0 -- chown vault:vault /vault/audit/audit.log
}

enable_dr_replication () {
    login_to_vault
    kubectl exec -ti -n vault vault-0 -- vault read sys/replication/status -format=json | jq .data.dr.mode | grep -q primary
    if [ $? -eq 0 ] 
    then 
        echo "INFO: DR replication is already configured" 
    else 
        echo "INFO: Enabling DR replication" 
        kubectl exec -ti -n vault vault-0 -- vault write -f sys/replication/dr/primary/enable
        kubectl exec -ti -n vault vault-0 -- vault write sys/replication/dr/primary/secondary-token id="secondary" -format=json  | jq -r .wrap_info.token > sat.txt
        login_to_vault_secondary
        kubectl exec -ti -n vault-secondary vault-secondary-0 -- vault write sys/replication/dr/secondary/enable token=$(cat sat.txt) 
    fi
}

enable_dr_replication_tls () {
    login_to_vault
    kubectl exec -ti -n vault vault-0 -- vault read sys/replication/status -format=json | jq .data.dr.mode | grep -q primary
    if [ $? -eq 0 ] 
    then 
        echo "INFO: DR replication is already configured" 
    else 
        echo "INFO: Enabling DR replication" 
        kubectl exec -ti -n vault vault-0 -- vault write -f sys/replication/dr/primary/enable
        kubectl exec -ti -n vault vault-0 -- vault write sys/replication/dr/primary/secondary-token id="secondary" -format=json  | jq -r .wrap_info.token > sat.txt
        login_to_vault_secondary
        kubectl exec -ti -n vault-secondary vault-secondary-0 -- vault write sys/replication/dr/secondary/enable token=$(cat sat.txt) ca_file=/vault/vault-tls/vault.ca
    fi
}

configure_test_secrets_engine () {
    kubectl exec -ti -n vault vault-0 -- vault secrets list | grep -q test
    if [ $? -eq 0 ] 
    then 
        echo "INFO: test secrets engine is already configured" 
    else 
        echo 'INFO: Setting up test secrets engine'
        kubectl exec -ti vault-0 -n vault -- vault secrets enable -path=test kv-v2
        kubectl exec -ti vault-0 -n vault -- vault kv put test/secret username="static-username" password="static-password"
    fi
}

enable_k8s_auth () {
    kubectl exec -ti -n vault vault-0 -- vault auth list | grep -q kubernetes
    if [ $? -eq 0 ] 
    then 
        echo 'INFO: k8s auth method already enabled'
    else
        echo 'INFO: Configuring k8s auth method'
        kubectl exec -ti -n vault vault-0 -- vault auth enable kubernetes
    fi
}

configure_k8s_auth () {
    echo 'INFO: Configuring k8s auth method'
    kubectl exec -ti -n vault vault-0 -- vault write auth/kubernetes/config \
        kubernetes_host="https://10.96.0.1:443" kubernetes_ca_cert="$KUBE_CA_CERT" disable_local_ca_jwt="true"
}

set_vault_policy () {
    kubectl exec -ti -n vault vault-0 -- vault policy list | grep -q test-policy
    if [ $? -eq 0 ] 
    then 
        echo "INFO: test-policy already exists" 
    else 
        echo 'INFO: Writing Vault policy'
        kubectl exec -ti -n vault vault-0 -- vault policy write test-policy - <<EOF
            path "test/data/secret" {
            capabilities = ["read"]
            }
            path "test/data/database/config" {
            capabilities = ["read"]
            }
            path "database/creds/readonly" {
            capabilities = ["read"]
            }
EOF
fi
}

configure_k8s_auth_role () {
    kubectl exec -ti -n vault vault-0 -- vault list auth/kubernetes/role | grep -q test-role
    if [ $? -eq 0 ] 
    then 
        echo "INFO: k8s auth role already exists" 
    else 
        echo "INFO: Configuring k8s auth method role"
        kubectl exec -ti -n vault vault-0 -- vault write auth/kubernetes/role/test-role \
        bound_service_account_names="vault,test-sa,default,internal-app,postgres-service-account,vault" \
        bound_service_account_namespaces="vault,vso,default" \
        policies=test-policy \
        ttl=24h
    fi
}

login_to_vault () {
    echo 'INFO: Logging into Vault'
    kubectl exec -ti -n vault vault-0 -- vault login $(jq -r ".root_token" ../setup/init.json)
}

login_to_vault_secondary () {
    echo 'INFO: Logging into Vault'
    kubectl exec -ti -n vault-secondary vault-secondary-0 -- vault login $(jq -r ".root_token" ../setup/init_secondary.json)
}

set_ent_license () {
    kubectl get secrets -n vault | grep -q vault-ent-license
    if [ $? -eq 0 ] 
    then 
        echo "INFO: Vault license already exist" 
    else 
        echo 'INFO: Setting license'
        secret=$VAULT_LICENSE
        kubectl create secret generic vault-ent-license -n vault --from-literal="license=${secret}"
    fi
}

set_ent_license_secondary () {
    kubectl get secrets -n vault-secondary | grep -q vault-ent-license
    if [ $? -eq 0 ] 
    then 
        echo "INFO: Vault license already exist" 
    else 
        echo 'INFO: Setting license'
        secret=$VAULT_LICENSE
        kubectl create secret generic vault-ent-license -n vault-secondary --from-literal="license=${secret}"
    fi
}

install_vault_helm () {
    helm ls -n vault | grep -q vault
    if [ $? -eq 0 ] 
    then 
        echo "INFO: Vault Helm chart already deployed" 
    else 
        echo "INFO: Installing Vault Helm chart"
        helm install vault hashicorp/vault -n vault --create-namespace --values ../helm-chart-values-files/vault-values-updated.yaml
    fi
}

install_vault_with_consul_helm () {
    echo "INFO: Installing Vault Helm chart"
    helm install vault hashicorp/vault -n vault --create-namespace --values ../helm-chart-values-files/vault-consul-values-updated.yaml
}

init_vault () {
    echo 'INFO: Waiting for container to start'
    while [[ $(kubectl get pods -n vault -l app.kubernetes.io/name=vault -o jsonpath='{.items[*].status.containerStatuses[0].started}') != true* ]]; 
    do
    sleep 1
    done
    echo 'INFO: Initializing vault-0'
    sleep 5
    kubectl exec -ti vault-0 -n vault -- vault operator init -key-shares=1 -key-threshold=1 -format=json > init.json
    sleep 5
}

unseal_vault () {
    echo 'INFO: Unsealing vault-0'
    export VAULT_UNSEAL_KEY=$(jq -r ".unseal_keys_b64[]" ../setup/init.json)
    kubectl exec -n vault vault-0 -- vault operator unseal $VAULT_UNSEAL_KEY
    sleep 5
}

install_vault_helm_secondary () {
    helm ls -n vault-secondary | grep -q vault
    if [ $? -eq 0 ] 
    then 
        echo "INFO: Vault Helm chart already deployed" 
    else 
        echo "INFO: Installing Vault Helm chart"
        helm install vault-secondary hashicorp/vault -n vault-secondary --create-namespace --values ../helm-chart-values-files/vault-values-secondary-updated.yaml
    fi
}

init_vault_secondary () {
    echo 'INFO: Waiting for container to start'
    while [[ $(kubectl get pods -n vault-secondary -l app.kubernetes.io/name=vault -o jsonpath='{.items[*].status.containerStatuses[0].started}') != true* ]]; 
    do
    sleep 1
    done
    echo 'INFO: Initializing vault-secondary-0'
    sleep 5
    kubectl exec -ti vault-secondary-0 -n vault-secondary -- vault operator init -key-shares=1 -key-threshold=1 -format=json > init_secondary.json
    sleep 5
}

unseal_vault_secondary () {
    echo 'INFO: Unsealing vault-secondary-0'
    export VAULT_UNSEAL_KEY_SECONDARY=$(jq -r ".unseal_keys_b64[]" ../setup/init_secondary.json)
    kubectl exec -n vault-secondary vault-secondary-0 -- vault operator unseal $VAULT_UNSEAL_KEY_SECONDARY
    sleep 5
}

create_test_sa_resources () {
    kubectl apply -f ../manifests/test-resources.yaml
}

create_postgres_service_account () {
    kubectl get sa | grep -q postgres-service-account
    if [ $? -eq 0 ] 
    then 
        echo "INFO: postgres-service-account service account already exist" 
    else 
        echo "INFO: Creating service account postgres-service-account" 
        kubectl create sa postgres-service-account
    fi
}

deploy_db_app () {
    echo "INFO: Deploying application"
    kubectl apply --filename ../manifests/sample-app.yaml
}

init_vault_auto_unseal () {
    echo 'INFO: Waiting for container to start'
    while [[ $(kubectl get pods -n vault -l app.kubernetes.io/name=vault -o jsonpath='{.items[*].status.containerStatuses[0].started}') != true* ]] 
    do
    sleep 1
    done
    echo 'INFO: Initializing vault-0'
    sleep 5
    kubectl exec -n vault vault-auto-unseal-0 -- vault operator init -key-shares=1 -key-threshold=1 -format=json > init_auto_unseal.json
    sleep 5
}

unseal_vault_auto_unseal () {
    echo 'INFO: Unsealing vault-0'
    export VAULT_UNSEAL_KEY_AUTO_UNSEAL=$(jq -r ".unseal_keys_b64[]" init_auto_unseal.json)
    kubectl exec -n vault vault-auto-unseal-0 -- vault operator unseal $VAULT_UNSEAL_KEY_AUTO_UNSEAL
    sleep 5
}

login_to_vault_auto_unseal () {
    echo 'INFO: Logging into Vault'
    kubectl exec -n vault vault-auto-unseal-0 -- vault login $(jq -r ".root_token" init_auto_unseal.json)
}

init_vault_using_auto_unseal () {
    echo 'INFO: Waiting for container to start'
    while [[ $(kubectl get pods -n vault -l app.kubernetes.io/name=vault -o jsonpath='{.items[*].status.containerStatuses[0].started}') != true* ]] 
    do
    sleep 1
    done
    echo 'INFO: Initializing vault-0'
    sleep 5
    kubectl exec -n vault vault-0 -- vault operator init -recovery-shares=1 -recovery-threshold=1 -format=json > init.json
    sleep 5
}

set_ent_license_auto_unseal_pod () {
    kubectl get secrets -n vault | grep -q vault-ent-license
    if [ $? -eq 0 ] 
    then 
        echo "INFO: Vault license already exist" 
    else 
        echo 'INFO: Setting license'
        secret=$VAULT_LICENSE
        kubectl create secret -n vault generic vault-ent-license --from-literal="license=${secret}"
    fi
}

set_ent_license_transit () {
    kubectl get secrets -n vault | grep -q vault-ent-license
    if [ $? -eq 0 ] 
    then 
        echo "INFO: Vault license already exist" 
    else 
        echo 'INFO: Setting license'
        secret=$VAULT_LICENSE
        kubectl create secret -n vault generic vault-ent-license --from-literal="license=${secret}"
    fi
}

enable_approle () {
    kubectl exec -ti -n vault vault-0 -- vault auth list | grep -q approle
    if [ $? -eq 0 ] 
    then 
        echo "INFO: App role already exists" 
    else 
        echo "INFO: Enabling App role"
        kubectl exec -ti -n vault vault-0 -- vault auth enable approle
    fi
}

write_approle_config () {
    kubectl exec -ti -n vault vault-0 -- vault write auth/approle/role/my-app-role \
        secret_id_ttl=10m \
        token_ttl=20m \
        token_max_ttl=30m \
        token_policies=test-policy
}

create_clusterrolebinding_for_jwt_auth () {
    kubectl get clusterrolebindings.rbac.authorization.k8s.io | grep -q oidc-reviewer
    if [ $? -eq 0 ] 
    then 
        echo "INFO: oidc-reviewer clusterrolebinding already exists"
    else
        echo "INFO: Creating oidc-reviewer clusterrolebinding"
        kubectl create clusterrolebinding oidc-reviewer  \
            --clusterrole=system:service-account-issuer-discovery \
            --group=system:unauthenticated
    fi
}

enable_jwt_auth () {
    kubectl exec -n vault vault-0 -- vault auth list | grep -q jwt
    if [ $? -eq 0 ] 
    then 
        echo "INFO: JWT auth already enabled" 
    else 
        echo "INFO: Enabling JWT auth" 
        kubectl exec -n vault vault-0 -- vault auth enable jwt
    fi
}

write_jwt_config () {
    kubectl exec -n vault vault-0 -- vault write auth/jwt/config \
        oidc_discovery_url=https://kubernetes.default.svc.cluster.local \
        oidc_discovery_ca_pem=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
}

create_jwt_role () {
    kubectl exec -ti -n vault vault-0 -- vault write auth/jwt/role/test-role \
        role_type="jwt" \
        bound_audiences="https://kubernetes.default.svc.cluster.local" \
        user_claim="sub" \
        bound_subject="system:serviceaccount:vault:vault" \
        policies="test-policy" \
        ttl="1h"
}

create_jwt_role_for_app_pod () {
    kubectl exec -ti -n vault vault-0 -- vault write auth/jwt/role/test-role \
        role_type="jwt" \
        bound_audiences="https://kubernetes.default.svc.cluster.local" \
        user_claim="sub" \
        bound_subject="system:serviceaccount:default:postgres-service-account" \
        policies="test-policy" \
        ttl="1h"
}

write_k8s_auth_config () {
    kubectl exec -ti -n vault vault-0 -- vault write auth/kubernetes/config kubernetes_host="https://10.96.0.1:443" disable_local_ca_jwt=false
}

create_clusterrolebinding_for_k8s_auth () {
    kubectl get clusterrolebindings.rbac.authorization.k8s.io | grep -q k8s_token-review-clusterrolebindings
    if [ $? -eq 0 ] 
    then 
        echo "INFO: k8s_token-review-clusterrolebindings ClusterRoleBinding already exist" 
    else 
        echo "INFO: Creating ClusterRoleBinding" 
        kubectl apply -f ../manifests/k8s-auth-clusterrolebinding.yaml
fi
}

enable_ldap_auth () {
    kubectl exec -ti -n vault vault-0 -- vault auth enable -path=ldap ldap
}

write_ldap_auth_config () {
    kubectl exec -ti -n vault vault-0 -- vault write auth/ldap/config \
        url="ldap://openldap-auth-method.default.svc.cluster.local:1389" \
        userdn="ou=users,dc=example,dc=org" \
        groupdn="ou=users,dc=example,dc=org" \
        binddn="cn=admin,dc=example,dc=org" \
        userattr="uid" \
        bindpass="adminpassword" \
        starttls=false
}

enable_ldap_secrets_engine () {
    kubectl exec -ti -n vault vault-0 -- vault secrets enable ldap
}

write_ldap_secrets_engine_config () {
    kubectl exec -ti -n vault vault-0 -- vault write ldap/config \
        binddn="cn=admin,dc=example,dc=org" \
        bindpass=adminpassword \
        url="ldap://openldap-secrets-engine.default.svc.cluster.local:1389"
}

create_ldap_secrets_engine_static_role () {
    kubectl exec -ti -n vault vault-0 -- vault write ldap/static-role/hashicorp-ldap \
        dn='cn=user01,ou=users,dc=example,dc=org' \
        username='user01' \
        rotation_period="24h"
}

write_database_config () {
    export PG_IP=$(kubectl get pod postgres --template '{{.status.podIP}}')
    kubectl exec -ti -n vault vault-0 -- vault write database/config/postgresql plugin_name=postgresql-database-plugin connection_url="postgresql://{{username}}:{{password}}@$PG_IP:5432/postgres?sslmode=disable" allowed_roles=readonly username="root"  password="rootpassword"
}

write_database_role () {
    kubectl exec -ti -n vault vault-0 -- vault write database/roles/readonly \
        db_name="postgresql" \
        creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
        GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
        default_ttl="1m" \
        max_ttl="1m"
}