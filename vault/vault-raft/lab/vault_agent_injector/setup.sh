configure_secrets_engine () {
    echo 'INFO: Setting up kv secrets engine'
    kubectl exec -ti vault-0 -- vault secrets enable -path=test kv-v2
    kubectl exec -ti vault-0 -- vault kv put test/secret username="static-username" password="static-password"
}

configure_k8s_auth_role () {
    kubectl exec -ti vault-0 -- vault write auth/kubernetes/role/test-role \
        bound_service_account_names=test-sa \
        bound_service_account_namespaces=vault \
        policies=policy1 \
        ttl=24h
}

set_vault_policy () {
    echo 'INFO: Writing Vault policy'
    kubectl exec -ti vault-0 -- vault policy write test-policy - <<EOF
        path "test/data/secret" {
        capabilities = ["read"]
        }
EOF
}

source ../../common.sh
install_vault_helm
set_ent_license
init_vault
unseal_vault
login_to_vault
configure_k8s_auth
configure_secrets_engine
configure_k8s_auth_role
set_vault_policy
deploy_app
