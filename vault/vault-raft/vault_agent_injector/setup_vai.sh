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
    echo 'INFO: Initializing vault-0'
    sleep 30
    kubectl exec vault-0 -- vault operator init -key-shares=1 -key-threshold=1 -format=json > init.json
    sleep 30
}

unseal_vault () {
    echo 'INFO: Unsealing vault-0'
    export VAULT_UNSEAL_KEY=$(jq -r ".unseal_keys_b64[]" init.json)
    kubectl exec vault-0 -- vault operator unseal $VAULT_UNSEAL_KEY
    sleep 15
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
    kubectl exec -ti vault-0 -- vault secrets enable -path=test kv
    kubectl exec -ti vault-0 -- vault kv put test/secret username="bob" password="1234"
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
    # Write a Vault policy that enables read for the secrets at specified path
    kubectl exec -ti vault-0 -- vault policy write test-policy - <<EOF
        path "test/secret" {
        capabilities = ["read"]
        }
EOF
}

configure_k8s_auth_role () {
    echo "INFO: Configuring k8s auth method role"
    # Create k8s auth role to connect k8s service account, k8s namespace, Vault policy
    kubectl exec -ti vault-0 -- vault write auth/kubernetes/role/test-role \
        bound_service_account_names=test-sa \
        bound_service_account_namespaces=default \
        policies=test-policy \
        ttl=24h
    # Create k8s service account 
    kubectl create sa test-sa
}

deploy_app () {
    echo "INFO: Deploying application"
    kubectl apply --filename nginx-deployment.yaml
}

install_vault_helm
set_ent_license
init_vault
unseal_vault
add_nodes_to_cluster
login_to_vault
configure_secrets_engine
configure_k8s_auth
set_vault_policy
configure_k8s_auth_role
deploy_app