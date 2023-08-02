source ../../common.sh
install_vault_helm
set_ent_license
init_vault
unseal_vault
login_to_vault
configure_secrets_engine
configure_k8s_auth

configure_k8s_auth_role () {
    echo "INFO: Configuring k8s auth method role"
    # Create k8s auth role to connect k8s service account, k8s namespace, Vault policy
    kubectl exec -ti vault-0 -- vault write auth/kubernetes/role/test-role \
        bound_service_account_names=test-sa \
        bound_service_account_namespaces=vault \
        policies=policy1 \
        ttl=24h
    # Create k8s service account
}

configure_k8s_auth_role

source ../../common.sh
set_vault_policy    
deploy_app
