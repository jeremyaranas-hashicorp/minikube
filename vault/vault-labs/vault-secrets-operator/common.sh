#!/usr/bin/env bash

configure_secrets_engine () {
    login_to_vault
    echo 'INFO: Setting up kv secrets engine'
    kubectl exec -ti vault-0 -n vault -- vault secrets enable -path=test kv-v2
    kubectl exec -ti vault-0 -n vault -- vault kv put test/secret username="static-username" password="static-password"
}

enable_k8s_auth () {
    login_to_vault
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
        kubernetes_host="https://10.96.0.1:443" disable_local_ca_jwt="false"
}

set_vault_policy () {
    login_to_vault
    echo 'INFO: Writing Vault policy'
    kubectl exec -ti -n vault vault-0 -- vault policy write vso-policy - <<EOF
        path "test/data/secret" {
        capabilities = ["read"]
        }
EOF
}

configure_role () {
    login_to_vault
    echo "INFO: Configuring role for k8s auth"
    kubectl exec -ti -n vault vault-0 -- vault write auth/kubernetes/role/vso-role \
        bound_service_account_names="default" \
        bound_service_account_namespaces="vso" \
        policies=vso-policy \
        audience=vault \
        ttl=24h
}

login_to_vault () {
    echo 'INFO: Logging into Vault'
     kubectl exec -ti -n vault vault-0 -- vault login $(jq -r ".root_token" init.json)
}

set_ent_license () {
    echo 'INFO: Setting license'
    secret=$VAULT_LICENSE
    kubectl create secret generic vault-ent-license -n vault --from-literal="license=${secret}"
}

install_vault_helm () {
    echo "INFO: Installing Vault Helm chart"
    helm install vault hashicorp/vault -n vault --create-namespace --values vault-values.yaml
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
    export VAULT_UNSEAL_KEY=$(jq -r ".unseal_keys_b64[]" init.json)
    kubectl exec -n vault vault-0 -- vault operator unseal $VAULT_UNSEAL_KEY
    sleep 5
}

create_service_account () {   
    echo 'INFO: Creating service account'  
    kubectl apply -f vso-sa.yaml
}