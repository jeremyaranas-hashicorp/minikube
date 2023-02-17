This repo spins up a Vault Raft cluster connected to PostgreSQL database secrets engine.

# Preqrequisites

* minikube

# Start Minikube

1. Start Minikube

`minikube start`

# Deploy Database 1 [PostgreSQL](https://www.containiq.com/post/deploy-postgres-on-kubernetes) 

1. Apply manifests

`kubectl apply -f postgres-config.yaml`
`kubectl apply -f postgres-pvc-pv.yaml` 
`kubectl apply -f postgres-deployment.yaml` 
`kubectl apply -f postgres-service.yaml` 

2. Connect to database (optional to test connection to database)

`k exec -it postgres-<1234> --  psql -h localhost -U root --password -p 5432 postgresql`

3. Get IP of PostgreSQL pod

`k get pod postgres-<1234> -o custom-columns=NAME:metadata.name,IP:status.podIP`

# Deploy [Vault](https://developer.hashicorp.com/vault/docs/platform/k8s/helm/examples/ha-with-raft) Raft cluster 

1. Add license to k8s secret (Vault license should be exported as local environment variable)

```
secret=$VAULT_LICENSE
kubectl create secret generic vault-ent-license --from-literal="license=${secret}"
```

2. Install Vault

`helm install vault hashicorp/vault --values helm-vault-values.yml`

3. Initialize Vault on vault-0

`kubectl exec vault-0 -- vault operator init -key-shares=1 -key-threshold=1 -format=json > cluster-keys.json`

4. Unseal vault-0

`VAULT_UNSEAL_KEY=$(jq -r ".unseal_keys_b64[]" cluster-keys.json)`
`kubectl exec vault-0 -- vault operator unseal $VAULT_UNSEAL_KEY`

5. Add nodes to clusters

`kubectl exec -ti vault-1 -- vault operator raft join http://vault-0.vault-internal:8200`
`kubectl exec -ti vault-1 -- vault operator unseal $VAULT_UNSEAL_KEY`
`kubectl exec -ti vault-2 -- vault operator raft join http://vault-0.vault-internal:8200`
`kubectl exec -ti vault-2 -- vault operator unseal $VAULT_UNSEAL_KEY`

# Enable Database Secrets Engine

1. Remote to vault-0 pod

`kubectl exec --stdin=true --tty=true vault-0 -- /bin/sh`

2. Set IP address of PostgreSQL pods

`export PG_IP=<ip_addr>:5432`

3. Login to Vault

`vault login <token>`

4. Enable secrets engine for database 1

`vault secrets enable database`

5. Write database 1

```
vault write database/config/postgresql \
    plugin_name=postgresql-database-plugin \
    allowed_roles="*" \
    connection_url="postgresql://{{username}}:{{password}}@$PG_IP/postgres?sslmode=disable" \
    username="root" \
    password="rootpassword"
```

6. Write database 1 role

```
vault write database/roles/my-role \
    db_name="postgresql" \
    creation_statements="CREATE ROLE \"{{name}}\" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}'; \
        GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"{{name}}\";" \
    default_ttl="1h" \
    max_ttl="24h"
```

7.  Generate leases database 1

```
count=1000
for i in $(seq $count); do
    vault read database/creds/my-role
done
```

8. Generate leases database 2

```
count=1000
for i in $(seq $count); do
    vault read database-2/creds/my-role
done
```

9. Check number of leases on database 1

`vault list -format=json sys/leases/lookup/database/creds/my-role/ | wc -l`

10. Check number of leases on database 2

`vault list -format=json sys/leases/lookup/database-2/creds/my-role/ | wc -l`