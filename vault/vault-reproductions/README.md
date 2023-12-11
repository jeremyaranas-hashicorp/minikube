This repo spins up a Vault Raft cluster in Kubernetes using the Vault Helm chart

# Prerequisites

* `jq`
* `kubectl`
* `minikube`
* `VAULT_LICENSE` env variable (add to bashrc or zshrc)
* `kubectl` shortcut (optional)
  * Add to bashrc or zshrc
    * `alias k=kubectl`
    * `complete -o default -F __start_kubectl k`

# Deploy Vault cluster in Kubernetes

Start Minikube cluster
```
minikube start
```

Initialize primary cluster\
`cd` to **setup** directory
```
./init-primary.sh
```

Initialize secondary cluster (optional, only needed for replication)\
`cd` to **setup** directory
```
./init-secondary.sh
```

# Reproduction Scenarios

`cd` to **configure_components** directory

### CSI Provider

```
./csi_provider.sh
```

Check that secret exist in app pod 
```
kubectl exec -n vault csi-app-pod -- cat /mnt/secrets-store/test-object
```

### JWT Auth Method Using Kubernetes as OIDC Provider

```
./jwt_auth.sh
```

Test login using JWT auth method
```
kubectl exec -ti -n vault vault-0 -- vault write auth/jwt/login role=test-role jwt=@/var/run/secrets/kubernetes.io/serviceaccount/token
```

### Kubernetes Auth Method

```
./k8s_auth.sh
```

Test login using long-lived token from service account
```
SA_JWT=$(kubectl get secret test-secret -n vault -o go-template='{{ .data.token }}' | base64 --decode)
```
```
kubectl exec -ti -n vault vault-0 -- curl -k --request POST --data '{"jwt": "'$SA_JWT'", "role": "test-role"}' http://127.0.0.1:8200/v1/auth/kubernetes/login
```

Test login using local JWT from Vault pod
```
VAULT_POD_LOCAL_JWT=$(kubectl exec -ti -n vault vault-0 -- cat /var/run/secrets/kubernetes.io/serviceaccount/token)
```      
```
kubectl exec -ti -n vault vault-0 -- curl -k --request POST --data '{"jwt": "'$VAULT_POD_LOCAL_JWT'", "role": "test-role"}' http://127.0.0.1:8200/v1/auth/kubernetes/login
```

Deploy app pod to test k8s auth 
```
./k8s_auth-app-pod.sh
```

Export app pod local JWT
```
APP_POD_LOCAL_JWT=$(kubectl exec -ti -n vault alpine -- cat /var/run/secrets/kubernetes.io/serviceaccount/token)
```

Authenticate from app pod to Vault using local JWT
```
kubectl exec -ti -n vault alpine -- curl -k --request POST --data '{"jwt": "'$APP_POD_LOCAL_JWT'", "role": "test-role"}' http://vault-active.vault.svc.cluster.local:8200/v1/auth/kubernetes/login
```

### Kubernetes Auth Method with External Vault

Deploy application pod
`cd` to **setup** directory
```
./application_pod.sh
```

Spin up Vault server
```
vault server -dev -dev-root-token-id root
```

Export VAULT_ADDR
```
export VAULT_ADDR='http://127.0.0.1:8200'
```

Enable k8s auth 
```
vault auth enable kubernetes
```

Set ENV vars for k8s auth method config
```
KUBE_CA_CERT=$(kubectl config view --raw --minify --flatten --output='jsonpath={.clusters[].cluster.certificate-authority-data}' | base64 --decode)
```
```
KUBE_HOST=$(kubectl config view --raw --minify --flatten --output='jsonpath={.clusters[].cluster.server}')
```

Set up k8s auth method
```
vault write auth/kubernetes/config kubernetes_host="$KUBE_HOST" kubernetes_ca_cert="$KUBE_CA_CERT" issuer="https://kubernetes.default.svc.cluster.local" disable_local_ca_jwt="true"
```

Create role for k8s auth
```
vault write auth/kubernetes/role/test-role bound_service_account_names="vault,test-sa,default,postgres-service-account" bound_service_account_namespaces="vault,vso,default" policies=test-policy ttl=24h
```

Get Minikube host IP and set ENV var
```
minikube ssh
```
```
dig +short host.docker.internal
```

Exit Minikube environment
```
exit
```

Set ENV var for Minikube IP
```
MINIKUBE_HOST_IP=<IP>
```

Create a ClusterRoleBinding 
```
cat <<EOF | kubectl create -f -  
---  
apiVersion: rbac.authorization.k8s.io/v1  
kind: ClusterRoleBinding  
metadata:  
  name: token-review-clusterrolebindings  
roleRef:  
  apiGroup: rbac.authorization.k8s.io  
  kind: ClusterRole  
  name: system:auth-delegator  
subjects: 
  - kind: ServiceAccount  
    name: default
    namespace: vault
EOF
```

Get app pod local JWT
```
APP_POD_LOCAL_JWT=$(kubectl exec -ti -n vault alpine -- cat /var/run/secrets/kubernetes.io/serviceaccount/token)
```

Log into Vault using k8s auth from app pod
```
kubectl exec -ti -n vault alpine -- curl -vv --request POST --data '{"jwt": "'$APP_POD_LOCAL_JWT'", "role": "test-role"}' http://$MINIKUBE_HOST_IP:8200/v1/auth/kubernetes/login
```

### Replication

Enable PR replication 
```
./performance-replication.sh
``` 

Enable DR replication
```
./dr-replication.sh
``` 

### TLS

Spin up TLS cluster
`cd` to **setup** directory
```
./init_cluster_tls.sh
```

### Vault Agent with Dynamic Postgres Credentials

```
./vault-agent.sh
```

Deploy Postgres pod
```
./postgresql-app-pod-01.sh
```

Get IP of Postgres pod
```
export PG_IP=$(kubectl get pod postgres --template '{{.status.podIP}}')
```

Write database config
```
kubectl exec -ti -n vault vault-0 -- vault write database/config/postgresql plugin_name=postgresql-database-plugin connection_url="postgresql://{{username}}:{{password}}@$PG_IP:5432/postgres?sslmode=disable" allowed_roles=readonly username="root"  password="rootpassword"
```

Create a file for the Postgres creation statements in the Vault pod
```
kubectl exec -ti -n vault vault-0 -- sh
```

Create file
```
vi /tmp/readonly.sql
``` 

Add the following content
```
CREATE ROLE "{{name}}" WITH LOGIN PASSWORD '{{password}}' VALID UNTIL '{{expiration}}' INHERIT;
GRANT ro TO "{{name}}";
```

Exit pod
```
exit
```

Write role for database config
```
kubectl exec -ti -n vault vault-0 -- vault write database/roles/readonly db_name=postgresql creation_statements=@/tmp/readonly.sql default_ttl=1m max_ttl=1m
```

Create roles in Postgres
```
kubectl exec -ti postgres -- sh
```

Run the following commands
```
psql -U root -c "CREATE ROLE \"ro\" NOINHERIT;"
```
```
psql -U root -c "GRANT SELECT ON ALL TABLES IN SCHEMA public TO \"ro\";"
```

Exit pod
```
exit
```

Update Kubernetes auth method config to work with sample application pod
```
kubectl exec -ti -n vault vault-0 -- vault write auth/kubernetes/config kubernetes_host="https://10.96.0.1:443"
```

Deploy sample application
```
./sample_app.sh
```

Check that credentials are automatically updated in sample application pod
```
kubectl exec -ti -n vault orgchart-<123> -- sh
```

Check database-creds.txt to see credentials update
```
watch -n 1 cat /vault/secrets/database-creds.txt
```

Check that credentials are renewed in Postgres pod
```
kubectl exec -ti postgres -- sh
```

Run while loop to see credentials update
```
while :; do psql -U root -c "SELECT usename, valuntil FROM pg_user;"; sleep 1; done
```

### Vault Agent

```
./vault-agent.sh
```

Check that secret exists in postgres app pod
```
kubectl exec -ti postgres-<pod> -- cat /vault/secrets/password.txt
```

Configure Vault Agent with JWT auto-auth
```
./vault-agent-jwt-auto-auth.sh
```

Check that config.json is rendered
```
kubectl exec -ti postgres-<pod> -c vault-agent -- sh
```
```
cat /home/vault/config.json
```

### Vault Secrets Operator

```
./vault-secrets-operator.sh
```

Retrieve k8s secret
```
kubectl get secret -n vso secretkv -o jsonpath="{.data.password}" | base64 --decode
```

### Consul Backend

```
helm repo add hashicorp https://helm.releases.hashicorp.com
```
```
helm repo update
```

Deploy Consul Helm chart 
```
helm install consul hashicorp/consul --values helm_chart_value_files/consul-values.yaml
```
Deploy Vault Helm chart
```
helm install vault hashicorp/vault --values helm_chart_value_files/vault-consul-values.yaml
```
Init and unseal Vault
```
kubectl exec vault-0 -- vault operator init -key-shares=1 -key-threshold=1 -format=json > cluster-keys.json
```
```
VAULT_UNSEAL_KEY=$(cat cluster-keys.json | jq -r ".unseal_keys_b64[]")
```
```
kubectl exec vault-0 -- vault operator unseal $VAULT_UNSEAL_KEY
```


# Sources

* https://developer.hashicorp.com/vault/docs/platform/k8s/helm/examples/standalone-tls
* https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-minikube-tls#create-the-certificate