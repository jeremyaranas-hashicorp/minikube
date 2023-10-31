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

# Options

`cd` to **configure_components** directory

1. Enable Performance Replication 
   1. `./pr.sh`
2. Enable Kubernetes Authentication Method
   1. `./k8s_auth.sh`
      1. Test login using long-lived token from service account
         1. `SA_JWT=$(kubectl get secret test-sa -n vault -o go-template='{{ .data.token }}' | base64 --decode)`   
         2. `kubectl exec -ti -n vault vault-0 -- curl -k --request POST --data '{"jwt": "'$SA_JWT'", "role": "test-role"}' http://127.0.0.1:8200/v1/auth/kubernetes/login`
      2. Test login using local JWT from pod
         1. `POD_LOCAL_JWT=$(kubectl exec -ti -n vault vault-0 -- cat /var/run/secrets/kubernetes.io/serviceaccount/token)`
         2. `kubectl exec -ti -n vault vault-0 -- curl -k --request POST --data '{"jwt": "'$POD_LOCAL_JWT'", "role": "test-role"}' http://127.0.0.1:8200/v1/auth/kubernetes/login`
3. Enable Vault Secrets Operator
   1. `./vso.sh`
      1. Retrieve k8s secret
         1. `kubectl get secret -n vso test-k8s-secret -o jsonpath="{.data.password}" | base64 --decode`
4. Enable CSI Provider
   1. `./csi_provider.sh`
      1. Check that secret exist in app pod 
         1. `kubectl exec -n vault nginx -- cat /mnt/secrets-store/test-object`
5. Enable JWT auth method
   1. To test jwt login from Vault pod, uncomment `Create role to test JWT auth login from Vault pod using auto-auth` and `Login using JWT auth from Vault`
   2. To test jwt auto auth from app pod, uncomment `Create role for JWT auth for app pod`
   3. `./jwt_auth.sh`
6. Enable Vault Agent Injector (requires jwt_auth.sh to test JWT auth method auto-auth) 
   1. `./vai.sh`
      1. Check that secret exist in app pod
         1. `kubectl exec -ti -n vault web-app-<pod> -- cat /vault/secrets/password.txt`
      2. Check that auto_auth was configured in app pod for k8s auth (requires updating app.yaml annotations for k8s auth auto-auth)
         1. `kubectl exec -ti -n vault web-app-<pod> -c vault-agent -- sh`
         2. `cat /home/vault/config.json`
      3. Check that auto_auth was configured in app pod for jwt auth (requires updating app.yaml annotations for jwt auth auto-auth)
         1. `kubectl exec -ti -n vault web-app-<pod> -c vault-agent -- sh`
         2. `cat /home/vault/config.json`
      4. Check that secret exist in postgres pod (requires k8s_auth.sh and postgresql.sh to be run first)
         1. `kubectl exec -ti postgres-<1234> -- cat /vault/secrets/password.txt`
7. Configure [PostgreSQL](https://www.containiq.com/post/deploy-postgres-on-kubernetes) pod and database secrets engine
   1. `./postgresql.sh`
   2. Get IP of PostgreSQL pod
      1. `kubectl get pod postgres-<1234> -o custom-columns=NAME:metadata.name,IP:status.podIP`
      2. Login to Vault
         1. `source ../main/common.sh`
         2. `login_to_vault`
      3. Exec into vault-0 pod
         1. `kubectl exec --stdin=true --tty=true -n vault vault-0 -- /bin/sh`
         2. Set IP address of PostgreSQL pod
            1. `export PG_IP=<ip_addr>:5432`
         3. Enable database secrets engine
            1. `vault secrets enable database`
         4. Write database config
```
vault write database/config/postgresql \
    plugin_name=postgresql-database-plugin \
    allowed_roles="*" \
    connection_url="postgresql://{{username}}:{{password}}@$PG_IP/postgres?sslmode=disable" \
    username="root" \
    password="rootpassword"
```
         1. Write database role
```
vault write database/roles/my-role \
    db_name="postgresql" \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
        GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
    default_ttl="1m" \
    max_ttl="5m"
```
1. Enable TLS
   1. `cd` to **tls** directory
   2. `./enable_tls.sh`
   3. Unseal each pod once pods start


# Sources

* https://developer.hashicorp.com/vault/docs/platform/k8s/helm/examples/standalone-tls
* https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-minikube-tls#create-the-certificate

# TO-DO

* Create if statement to check if VSO namespace exist
* Create if statement to check if VSO Helm chart is already installed 
* Create if statement to check if CSI Helm chart is already installed
* Move `vault auth enable kubernetes` outside of configure_k8s_auth function and create if statement to check if k8s auth is already enabled
* Remove nginx Vault Agent and use PostgreSQL for Vault Agent
* Configure Vault Agent and PostgreSQL database credentials to see how renewal works
