This repo spins up a Vault Raft cluster in k8s using the Vault Helm chart.

# Prerequisites

* `jq`
* `kubectl`
* `minikube`
* `VAULT_LICENSE` env variable (add to bashrc or zshrc)
* `kubectl` shortcut (optional)
  * Add to bashrc or zshrc
    * `alias k=kubectl`
    * `complete -o default -F __start_kubectl k`

# Instructions

1. Start Minikube
   1. `minikube start`

2. Initialize primary cluster
   1. `cd` to **setup** directory
   2. `./init-primary.sh`

3. Initialize secondary cluster (optional)
   1. `cd` to **setup** directory
   2. `./init-secondary.sh`

4. Deploy an application pod for testing (optional)
   1. `cd` to **setup** directory
   2. `./application_pod.sh`

# Options

The following options will configure different components, for example, Vault Agent Injector, Vault Secrets Operator, etc. The scripts can be run in any order.

`cd` to **configure_components** directory

1. Enable Performance Replication 
   1. Requires secondary cluster 
   2. `./performance-replication.sh`
2. Enable Kubernetes Authentication Method
   1. `./k8s_auth.sh`
      1. Test login using long-lived token from service account
         1. `SA_JWT=$(kubectl get secret test-sa -n vault -o go-template='{{ .data.token }}' | base64 --decode)`   
         2. `kubectl exec -ti -n vault vault-0 -- curl -k --request POST --data '{"jwt": "'$SA_JWT'", "role": "test-role"}' http://127.0.0.1:8200/v1/auth/kubernetes/login`
      2. Test login using local JWT from Vault pod
         1. `VAULT_POD_LOCAL_JWT=$(kubectl exec -ti -n vault vault-0 -- cat /var/run/secrets/kubernetes.io/serviceaccount/token)`
         2. `kubectl exec -ti -n vault vault-0 -- curl -k --request POST --data '{"jwt": "'$VAULT_POD_LOCAL_JWT'", "role": "test-role"}' http://127.0.0.1:8200/v1/auth/kubernetes/login`
3. Deploy app pod for k8s auth
   1. `./k8s_auth-app-pod.sh`
      1. Export app pod local JWT
         1. `APP_POD_LOCAL_JWT=$(kubectl exec -ti -n vault alpine -- cat /var/run/secrets/kubernetes.io/serviceaccount/token)`
      2. Authenticate from app pod to Vault
         1. `kubectl exec -ti -n vault alpine -- curl -k --request POST --data '{"jwt": "'$APP_POD_LOCAL_JWT'", "role": "test-role"}' http://vault-active.vault.svc.cluster.local:8200/v1/auth/kubernetes/login`
4. Enable Vault Secrets Operator
   1. `./vault-secrets-operator.sh`
      1. Retrieve k8s secret
         1. `kubectl get secret -n vso test-k8s-secret -o jsonpath="{.data.password}" | base64 --decode`
5. Enable CSI Provider
   1. alpine app pod will need to be deleted if created from step 3
   2. `./csi_provider.sh`
      1. Check that secret exist in app pod 
         1. `kubectl exec -n vault alpine -- cat /mnt/secrets-store/test-object`
6. Enable JWT auth method 
   1. `./jwt_auth.sh`
      1. Test login using JWT auth method
         1. `kubectl exec -ti -n vault vault-0 -- vault write auth/jwt/login role=test-role jwt=@/var/run/secrets/kubernetes.io/serviceaccount/token`
7. Enable Vault Agent Injector 
   1. `./vault-agent.sh`
      1. Check that secret exists in postgres app pod 
         1. `kubectl exec -ti postgres-<pod> -- cat /vault/secrets/password.txt`
      2. Configure JWT auto-auth
         1. `./vault-agent-jwt-auto-auth.sh` 
         2. Check that config.json is rendered
            1. `kubectl exec -ti postgres-<pod> -c vault-agent -- sh`
            2. `cat /home/vault/config.json`
8. Configure [PostgreSQL](https://www.containiq.com/post/deploy-postgres-on-kubernetes) pod and database secrets engine 
   1. `./postgresql-app-pod.sh`
   2. Get IP of PostgreSQL pod
      1. `kubectl get pod postgres-<pod> -o custom-columns=NAME:metadata.name,IP:status.podIP`
      2. Exec into vault-0 pod
         1. `kubectl exec --stdin=true --tty=true -n vault vault-0 -- /bin/sh`
         2. Set IP address of PostgreSQL pod
            1. `export PG_IP=<ip_addr>:5432`
         3. Enable database secrets engine
            1. `vault secrets enable database`
         4. Write database config and role
   
```
# Config
vault write database/config/postgresql \
    plugin_name=postgresql-database-plugin \
    allowed_roles="*" \
    connection_url="postgresql://{{username}}:{{password}}@$PG_IP/postgres?sslmode=disable" \
    username="root" \
    password="rootpassword"
```

```
# Role
vault write database/roles/my-role \
    db_name="postgresql" \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
        GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
    default_ttl="1m" \
    max_ttl="5m"
```

8. Enable TLS
   1. `cd` to **tls** directory
   2. `./enable_tls.sh`
   3. Unseal each pod on the primary 
      1. `export VAULT_UNSEAL_KEY=$(jq -r ".unseal_keys_b64[]" ../setup/init.json)`
      2. `kubectl exec -ti -n vault vault-0 -- vault operator unseal $VAULT_UNSEAL_KEY`
      3. `kubectl exec -ti -n vault vault-1 -- vault operator unseal $VAULT_UNSEAL_KEY`
      4. `kubectl exec -ti -n vault vault-2 -- vault operator unseal $VAULT_UNSEAL_KEY`
   4. Check that VAULT_ADDR is using https
      1. `kubectl exec -ti -n vault vault-0 -- sh`
         1. `echo $VAULT_ADDR`
         2. `vault status`
   5. Unseal each pod on the secondary 
      1. `kubectl exec -ti -n vault-secondary vault-secondary-0 -- vault operator unseal $VAULT_UNSEAL_KEY`
      2. `kubectl exec -ti -n vault-secondary vault-secondary-1 -- vault operator unseal $VAULT_UNSEAL_KEY`
      3. `kubectl exec -ti -n vault-secondary vault-secondary-2 -- vault operator unseal $VAULT_UNSEAL_KEY`
   6. Check that VAULT_ADDR is using https
      1. `kubectl exec -ti -n vault-secondary vault-secondary-0 -- sh`
         1. `echo $VAULT_ADDR`
         2. `vault status`

# Sources

* https://developer.hashicorp.com/vault/docs/platform/k8s/helm/examples/standalone-tls
* https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-minikube-tls#create-the-certificate

# TO-DO

* Configure Vault Agent and PostgreSQL database credentials to see how renewal works