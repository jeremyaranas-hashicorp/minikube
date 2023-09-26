# Functions for vault and vault-secondary namespaces

enable_pr () {
    login_to_vault
    kubectl exec -ti -n vault vault-0 -- vault write -f sys/replication/performance/primary/enable
    kubectl exec -ti -n vault vault-0 -- vault write sys/replication/performance/primary/secondary-token id="secondary" -format=json  | jq -r .wrap_info.token > sat.txt
    login_to_vault_secondary
    # TLS
    # kubectl exec -ti -n vault-secondary vault-secondary-0 -- vault write sys/replication/performance/secondary/enable token=$(cat sat.txt) ca_file=/vault/vault-tls/vault.ca
    kubectl exec -ti -n vault-secondary vault-secondary-0 -- vault write sys/replication/performance/secondary/enable token=$(cat sat.txt) 

}

configure_secrets_engine () {
    echo 'INFO: Setting up kv secrets engine'
    kubectl exec -ti vault-0 -n vault -- vault secrets enable -path=test kv-v2
    kubectl exec -ti vault-0 -n vault -- vault kv put test/secret username="static-username" password="static-password"

}

configure_k8s_auth () {
    login_to_vault
    echo 'INFO: Configuring k8s auth method'
    kubectl exec -ti -n vault vault-0 -- vault auth enable kubernetes
    # Configure k8s auth method to use the location of the k8s API
    # In Minikube, the kubernetes_host is 10.96.0.1
    kubectl exec -ti -n vault vault-0 -- vault write auth/kubernetes/config \
    kubernetes_host="https://10.96.0.1:443"
}

set_vault_policy () {
    echo 'INFO: Writing Vault policy'
    kubectl exec -ti -n vault vault-0 -- vault policy write test-policy - <<EOF
        path "test/data/secret" {
        capabilities = ["read"]
        }
EOF
}

configure_k8s_auth_role () {
    echo "INFO: Configuring k8s auth method role"
    kubectl exec -ti -n vault vault-0 -- vault write auth/kubernetes/role/test-role \
        bound_service_account_names="vault,test-sa,default" \
        bound_service_account_namespaces="vault,vso" \
        policies=test-policy \
        ttl=24h
}

login_to_vault () {
    echo 'INFO: Logging into Vault'
     kubectl exec -ti -n vault vault-0 -- vault login $(jq -r ".root_token" init.json)
}

login_to_vault_secondary () {
    echo 'INFO: Logging into Vault'
     kubectl exec -ti -n vault-secondary vault-secondary-0 -- vault login $(jq -r ".root_token" init-secondary.json)
}

set_ent_license () {
    echo 'INFO: Setting license'
    # Vault license must be set using the VAULT_LICENSE environment variable
    # export VAULT_LICENSE="<license_string>"
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

set_ent_license_secondary () {
    echo 'INFO: Setting license'
    # Vault license must be set using the VAULT_LICENSE environment variable
    # export VAULT_LICENSE="<license_string>"
    secret=$VAULT_LICENSE
    kubectl create secret generic vault-ent-license -n vault-secondary --from-literal="license=${secret}"
}

install_vault_helm_secondary () {
    echo "INFO: Installing Vault Helm chart"
    helm install vault-secondary hashicorp/vault -n vault-secondary --create-namespace --values vault-values-secondary.yaml
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
    export VAULT_UNSEAL_KEY_SECONDARY=$(jq -r ".unseal_keys_b64[]" init-secondary.json)
    kubectl exec -n vault-secondary vault-secondary-0 -- vault operator unseal $VAULT_UNSEAL_KEY_SECONDARY
    sleep 5
}