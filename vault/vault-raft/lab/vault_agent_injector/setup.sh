source ../../common.sh
install_vault_helm
set_ent_license
init_vault
unseal_vault
login_to_vault
configure_secrets_engine
configure_k8s_auth

configure_k8s_auth_role () {
    kubectl exec -ti vault-0 -- vault write auth/kubernetes/role/test-role \
        bound_service_account_names=test-sa \
        bound_service_account_namespaces=vault \
        policies=policy1 \
        ttl=24h
}

configure_k8s_auth_role

source ../../common.sh
set_vault_policy    
deploy_app
