#!/usr/bin/env bash

install_vault_helm () {
    echo "INFO: Installing Vault Helm chart"
    helm install vault hashicorp/vault --values vault-values.yaml
}

set_ent_license () {
    echo 'INFO: Setting license'
    # Vault license must be set using the VAULT_LICENSE environment variable
    # export VAULT_LICENSE="<license_string>"
    secret=$VAULT_LICENSE
    kubectl create secret generic vault-ent-license --from-literal="license=${secret}"
}

init_vault () {
    echo 'INFO: Waiting for container to start'
    while [[ $(kubectl get pods -l app.kubernetes.io/name=vault -o jsonpath='{.items[*].status.containerStatuses[0].started}') != true* ]] 
    do
    sleep 1
    done
    echo 'INFO: Initializing vault-0'
    sleep 5
    kubectl exec vault-0 -- vault operator init -key-shares=1 -key-threshold=1 -format=json > init.json
    sleep 5
}

unseal_vault () {
    echo 'INFO: Unsealing vault-0'
    export VAULT_UNSEAL_KEY=$(jq -r ".unseal_keys_b64[]" init.json)
    kubectl exec vault-0 -- vault operator unseal $VAULT_UNSEAL_KEY
    sleep 5
}

add_nodes_to_cluster () {
    echo 'INFO: Adding nodes to cluster'
    kubectl exec -ti vault-1 -- vault operator raft join http://vault-0.vault-internal:8200
    kubectl exec -ti vault-1 -- vault operator unseal $VAULT_UNSEAL_KEY
    kubectl exec -ti vault-2 -- vault operator raft join http://vault-0.vault-internal:8200
    kubectl exec -ti vault-2 -- vault operator unseal $VAULT_UNSEAL_KEY
}

login_to_vault () {
    echo 'INFO: Logging into Vault'
    kubectl exec vault-0 -- vault login $(jq -r ".root_token" init.json)
}

configure_secrets_engine () {
    echo 'INFO: Setting up kv secrets engine'
    kubectl exec -ti vault-0 -- vault secrets enable -path=test kv-v2
    kubectl exec -ti vault-0 -- vault kv put test/secret username="static-username" password="static-password"
}

configure_k8s_auth () {
    echo 'INFO: Configuring k8s auth method'
    kubectl exec -ti vault-0 -- vault auth enable kubernetes
    # Configure k8s auth method to use the location of the k8s API
    # In Minikube, the kubernetes_host is 10.96.0.1
    kubectl exec -ti vault-0 -- vault write auth/kubernetes/config \
      kubernetes_host="https://10.96.0.1:443"
}

set_vault_policy () {
    echo 'INFO: Writing Vault policy'
    kubectl exec -ti vault-0 -- vault policy write test-policy - <<EOF
        path "test/data/secret" {
        capabilities = ["read"]
        }
EOF
}

configure_k8s_auth_role () {
    echo "INFO: Configuring k8s auth method role"
    kubectl exec -ti vault-0 -- vault write auth/kubernetes/role/test-role \
        bound_service_account_names=test-sa,vault \
        bound_service_account_namespaces=default,test-namespace \
        policies=test-policy \
        ttl=24h
    kubectl create sa test-sa
}

deploy_app () {
    echo "INFO: Deploying application"
    kubectl apply --filename nginx-deployment.yaml
}

install_vault_helm_namespace () {
    echo "INFO: Installing Vault Helm chart"
    helm install vault hashicorp/vault -n vault --create-namespace --values vault-values.yaml
}

install_vault_helm_namespace_secondary () {
    echo "INFO: Installing Vault Helm chart"
    helm install vault-secondary hashicorp/vault -n vault-secondary --create-namespace --values vault-values-secondary.yaml
}

set_ent_license_namespace () {
    echo 'INFO: Setting license'
    # Vault license must be set using the VAULT_LICENSE environment variable
    # export VAULT_LICENSE="<license_string>"
    secret=$VAULT_LICENSE
    kubectl create secret generic vault-ent-license -n vault --from-literal="license=${secret}"
}

set_ent_license_namespace_secondary () {
    echo 'INFO: Setting license'
    # Vault license must be set using the VAULT_LICENSE environment variable
    # export VAULT_LICENSE="<license_string>"
    secret=$VAULT_LICENSE
    kubectl create secret generic vault-ent-license -n vault-secondary --from-literal="license=${secret}"
}

init_vault_namespace () {
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

init_vault_namespace_secondary () {
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

unseal_vault_namespace () {
    echo 'INFO: Unsealing vault-0'
    export VAULT_UNSEAL_KEY=$(jq -r ".unseal_keys_b64[]" init.json)
    kubectl exec -n vault vault-0 -- vault operator unseal $VAULT_UNSEAL_KEY
    sleep 5
}

unseal_vault_namespace_secondary () {
    echo 'INFO: Unsealing vault-secondary-0'
    export VAULT_UNSEAL_KEY_SECONDARY=$(jq -r ".unseal_keys_b64[]" init-secondary.json)
    kubectl exec -n vault-secondary vault-secondary-0 -- vault operator unseal $VAULT_UNSEAL_KEY_SECONDARY
    sleep 5
}

add_nodes_to_cluster_namespace () {
    echo 'INFO: Adding nodes to cluster'
    kubectl exec -ti vault-1 -n vault -- vault operator raft join http://vault-0.vault-internal:8200
    kubectl exec -ti vault-1 -n vault -- vault operator unseal $VAULT_UNSEAL_KEY
    kubectl exec -ti vault-2 -n vault -- vault operator raft join http://vault-0.vault-internal:8200
    kubectl exec -ti vault-2 -n vault -- vault operator unseal $VAULT_UNSEAL_KEY
}

login_to_vault_namespace () {
    echo 'INFO: Logging into Vault'
    kubectl exec vault-0 -n vault -- vault login $(jq -r ".root_token" init.json)
}

login_to_vault_namespace_secondary () {
    echo 'INFO: Logging into Vault'
    kubectl exec vault-secondary-0 -n vault-secondary -- vault login $(jq -r ".root_token" init-secondary.json)
}

configure_secrets_engine_namespace () {
    echo 'INFO: Setting up kv secrets engine'
    kubectl exec -ti vault-0 -n vault -- vault secrets enable -path=test kv-v2
    kubectl exec -ti vault-0 -n vault -- vault kv put test/secret username="static-username" password="static-password"

}

configure_k8s_auth_namespace () {
    echo 'INFO: Configuring k8s auth method'
    kubectl exec -ti  vault-0 -n vault -- vault auth enable kubernetes
    # Configure k8s auth method to use the location of the k8s API
    # In Minikube, the kubernetes_host is 10.96.0.1
    kubectl exec -ti vault-0 -n vault -- vault write auth/kubernetes/config kubernetes_host="https://10.96.0.1:443" disable_local_ca_jwt=true disable_iss_validation=true kubernetes_ca_cert=@/run/secrets/kubernetes.io/serviceaccount/ca\.crt

}

set_vault_policy_namespace () {
    echo 'INFO: Writing Vault policy'
    kubectl exec -ti vault-0 -n vault -- vault policy write test-policy - <<EOF
        path "test/data/secret" {
        capabilities = ["read"]
        }
EOF
}

configure_k8s_auth_role_namespace () {
    echo "INFO: Configuring k8s auth method role"
    kubectl exec -ti  vault-0 -n vault -- vault write auth/kubernetes/role/test-role \
        bound_service_account_names=default \
        bound_service_account_namespaces="*" \
        audience="https://kubernetes.default.svc.cluster.local" \
        ttl=1h \
        token_policies=test-policy
}

init_vault_2 () {
    echo 'INFO: Waiting for container to start'
    while [[ $(kubectl get pods -l app.kubernetes.io/name=vault -o jsonpath='{.items[*].status.containerStatuses[0].started}') != true* ]] 
    do
    sleep 1
    done
    echo 'INFO: Initializing vault-secondary-0'
    sleep 5
    kubectl exec vault-secondary-0 -- vault operator init -key-shares=1 -key-threshold=1 -format=json > init-2.json
    sleep 5
}

unseal_vault_2 () {
    echo 'INFO: Unsealing vault-secondary-0'
    export VAULT_UNSEAL_KEY_2=$(jq -r ".unseal_keys_b64[]" init-2.json)
    kubectl exec vault-secondary-0 -- vault operator unseal $VAULT_UNSEAL_KEY_2
    sleep 5
}

login_to_vault_2 () {
    echo 'INFO: Logging into Vault'
    kubectl exec vault-secondary-0 -- vault login $(jq -r ".root_token" init-2.json)
}

init_vault_auto_unseal () {
    echo 'INFO: Waiting for container to start'
    while [[ $(kubectl get pods -l app.kubernetes.io/name=vault -o jsonpath='{.items[*].status.containerStatuses[0].started}') != true* ]] 
    do
    sleep 1
    done
    echo 'INFO: Initializing vault-auto-unseal-0'
    sleep 5
    kubectl exec vault-auto-unseal-0 -- vault operator init -key-shares=1 -key-threshold=1 -format=json > init-auto-unseal.json
    sleep 5
}

unseal_vault_auto_unseal () {
    echo 'INFO: Unsealing vault-auto-unseal-0'
    export VAULT_UNSEAL_KEY_AUTO_UNSEAL=$(jq -r ".unseal_keys_b64[]" init-auto-unseal.json)
    kubectl exec vault-auto-unseal-0 -- vault operator unseal $VAULT_UNSEAL_KEY_AUTO_UNSEAL
    sleep 5
}

login_to_vault_auto_unseal () {
    echo 'INFO: Logging into Vault'
    kubectl exec vault-auto-unseal-0 -- vault login $(jq -r ".root_token" init-auto-unseal.json)
}

init_vault_using_auto_unseal () {
    echo 'INFO: Waiting for container to start'
    while [[ $(kubectl get pods -l app.kubernetes.io/name=vault -o jsonpath='{.items[*].status.containerStatuses[0].started}') != true* ]] 
    do
    sleep 1
    done
    echo 'INFO: Initializing vault-0'
    sleep 5
    kubectl exec vault-0 -- vault operator init > init.json
    sleep 5
}

enable_dr () {
    login_to_vault_namespace
    kubectl exec -ti -n vault vault-0 -- vault write -f sys/replication/dr/primary/enable
    kubectl exec -ti -n vault vault-0 -- vault write sys/replication/dr/primary/secondary-token id="dr-secondary" -format=json  | jq -r .wrap_info.token > sat.txt
    login_to_vault_namespace_secondary
    kubectl exec -ti -n vault-secondary vault-secondary-0 -- vault write sys/replication/dr/secondary/enable token=$(cat sat.txt) ca_file=/vault/vault-tls/vault.ca
}




