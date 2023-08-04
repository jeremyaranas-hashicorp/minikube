source ../../common.sh
install_vault_helm
set_ent_license

# Wait for container to start
while [[ $(kubectl get pods -l app.kubernetes.io/name=vault -o jsonpath='{.items[*].status.containerStatuses[0].started}') != "true" ]]; 
do
 echo 'Waiting for container to start' 
done

init_vault
unseal_vault
login_to_vault
configure_k8s_auth

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


configure_secrets_engine
configure_k8s_auth_role


set_vault_policy () {
    echo 'INFO: Writing Vault policy'
    # Write a Vault policy that enables read for the secrets at specified path
    kubectl exec -ti vault-0 -- vault policy write test-policy - <<EOF
        path "test/data/secret" {
        capabilities = ["read"]
        }
EOF
}

set_vault_policy

source ../../common.sh
deploy_app
