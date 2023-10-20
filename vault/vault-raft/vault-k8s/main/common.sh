#!/usr/bin/env bash

enable_pr () {
    login_to_vault
    kubectl exec -ti -n vault vault-0 -- vault read sys/replication/status -format=json | jq .data.performance.mode | grep -q primary
    if [ $? -eq 0 ] 
    then 
        echo "INFO: PR is already configured" 
    else 
        echo "INFO: Enabling PR" 
        kubectl exec -ti -n vault vault-0 -- vault write -f sys/replication/performance/primary/enable
        kubectl exec -ti -n vault vault-0 -- vault write sys/replication/performance/primary/secondary-token id="secondary" -format=json  | jq -r .wrap_info.token > sat.txt
        login_to_vault_secondary
        # TLS
        # kubectl exec -ti -n vault-secondary vault-secondary-0 -- vault write sys/replication/performance/secondary/enable token=$(cat sat.txt) ca_file=/vault/vault-tls/vault.ca
        kubectl exec -ti -n vault-secondary vault-secondary-0 -- vault write sys/replication/performance/secondary/enable token=$(cat sat.txt) 
    fi
}

configure_secrets_engine () {
    login_to_vault
    kubectl exec -ti -n vault vault-0 -- vault secrets list | grep -q test
    if [ $? -eq 0 ] 
    then 
        echo "INFO: Secrets engine test is already configured" 
    else 
        echo 'INFO: Setting up kv secrets engine test'
        kubectl exec -ti vault-0 -n vault -- vault secrets enable -path=test kv-v2
        kubectl exec -ti vault-0 -n vault -- vault kv put test/secret username="static-username" password="static-password"
    fi
}

configure_k8s_auth () {
    echo 'INFO: Configuring k8s auth method'
    kubectl exec -ti -n vault vault-0 -- vault auth enable kubernetes
    kubectl exec -ti -n vault vault-0 -- vault write auth/kubernetes/config \
    kubernetes_host="https://10.96.0.1:443" disable_local_ca_jwt=false
}

set_vault_policy () {
    login_to_vault
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
EOF
fi
}

configure_k8s_auth_role () {
    login_to_vault
    kubectl exec -ti -n vault vault-0 -- vault list auth/kubernetes/role | grep -q test-role
    if [ $? -eq 0 ] 
    then 
        echo "INFO: k8s auth role already exists" 
    else 
        echo "INFO: Configuring k8s auth method role"
        kubectl exec -ti -n vault vault-0 -- vault write auth/kubernetes/role/test-role \
        bound_service_account_names="vault,test-sa,default" \
        bound_service_account_namespaces="vault,vso" \
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
     kubectl exec -ti -n vault-secondary vault-secondary-0 -- vault login $(jq -r ".root_token" ../setup/init-secondary.json)
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
        helm install vault hashicorp/vault -n vault --create-namespace --values ../helm_chart_value_files/vault-values.yaml
    fi
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
        helm install vault-secondary hashicorp/vault -n vault-secondary --create-namespace --values ../helm_chart_value_files/vault-values-secondary.yaml
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
    kubectl exec -ti vault-secondary-0 -n vault-secondary -- vault operator init -key-shares=1 -key-threshold=1 -format=json > init-secondary.json
    sleep 5
}

unseal_vault_secondary () {
    echo 'INFO: Unsealing vault-secondary-0'
    export VAULT_UNSEAL_KEY_SECONDARY=$(jq -r ".unseal_keys_b64[]" ../setup/init-secondary.json)
    kubectl exec -n vault-secondary vault-secondary-0 -- vault operator unseal $VAULT_UNSEAL_KEY_SECONDARY
    sleep 5
}

create_service_account () {
    kubectl get sa -n vault | grep -q test-sa
    if [ $? -eq 0 ] 
    then 
        echo "INFO: test-sa service account already exist" 
    else 
        echo "INFO: Creating service account test-sa" 
        kubectl apply -f ../manifests/service_account.yaml
    fi
}

create_secret () {
    kubectl get secret -n vault | grep -q test-sa
    if [ $? -eq 0 ] 
    then 
        echo "INFO: test-sa secret already exist" 
    else 
        echo "INFO: Creating secret test-sa"
        kubectl apply -f ../manifests/secret.yaml 
    fi
}