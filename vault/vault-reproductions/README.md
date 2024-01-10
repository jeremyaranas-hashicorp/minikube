This repo spins up a Vault cluster in Kubernetes using the Vault Helm chart

# Prerequisites

* `jq`
* `kubectl`
* `minikube`
* `VAULT_LICENSE` env variable (add to bashrc or zshrc)
* `kubectl` shortcut (optional)
  * Add to bashrc or zshrc
    * `alias k=kubectl`
    * `complete -o default -F __start_kubectl k`

HashiCorp Helm repo
```
helm repo add hashicorp https://helm.releases.hashicorp.com
```
```
helm repo update
```

# About This Environment

* The Vault pods in the primary cluster are deployed in the *vault* namespace
* The Vault pods in the secondary cluster are deployed in the *vault-secondary* namespace
* Audit logs are written to */vault/audit/audit.log* 
* Note that any files in */tmp/vault /tmp/vault-agent* or */tmp/vault-secondary* will be removed when deploying the TLS environment since the certificates are generated and saved in these directories
* The secondary cluster uses Raft as the storage backend and Shamir unseal 
  
## Init Keys

* Vault init keys can be found in the following files in the setup directory
  * init.json (primary cluster)  
  * init-secondary.json (secondary cluster)
  * init-auto-unseal.json (Transit cluster)

# Deploy Vault cluster in Kubernetes

Start Minikube cluster
```
minikube start
```
Initialize cluster
`cd` to **setup** directory
```
./init.sh
```
Follow prompts to set up environment

# Reproduction Scenarios

`cd` to **scripts** directory

## CSI Provider

This script configures the Vault CSI Provider and enables the csi-app-pod application pod to consume Vault secrets using the CSI secrets store volume.

```
./csi_provider.sh
```
Check that secret was retrieved from Vault and mounted to the application pod's CSI volume
```
kubectl exec -n vault csi-app-pod -- cat /mnt/secrets-store/test-object
```
**TLS**
```
./csi_provider_tls.sh
```
Check that secret was retrieved from Vault and mounted to the application pod's CSI volume
```
kubectl exec -n vault csi-app-pod -- cat /mnt/secrets-store/test-object
```

## JWT Auth Method Using Kubernetes as OIDC Provider

This script configures the JWT auth method and enables a user to login using the test-role role and service account token.

```
./jwt_auth.sh
```
Login to Vault using JWT auth method
```
kubectl exec -ti -n vault vault-0 -- vault write auth/jwt/login role=test-role jwt=@/var/run/secrets/kubernetes.io/serviceaccount/token
```

## Kubernetes Auth Method

This script configures the Kubernetes auth method and enables authentication to Vault using a service account token.

```
./k8s_auth.sh
```
Login to Vault using service account token
```
SA_JWT=$(kubectl get secret test-secret -n vault -o go-template='{{ .data.token }}' | base64 --decode)
```
```
kubectl exec -ti -n vault vault-0 -- curl -k --request POST --data '{"jwt": "'$SA_JWT'", "role": "test-role"}' http://127.0.0.1:8200/v1/auth/kubernetes/login
```
**TLS**
```
./k8s_auth.sh
```
Login to Vault using service account token 
```
SA_JWT=$(kubectl get secret test-secret -n vault -o go-template='{{ .data.token }}' | base64 --decode)
```
```
kubectl exec -ti -n vault vault-0 -- curl -k --request POST --data '{"jwt": "'$SA_JWT'", "role": "test-role"}' https://127.0.0.1:8200/v1/auth/kubernetes/login
```

### Deploy App Pod to Test k8s Auth 

This script configures an alpine application pod and enables login to Vault using the application pod's service account token.

```
./k8s_auth-app-pod.sh
```
Export application pod service account token
```
APP_POD_LOCAL_JWT=$(kubectl exec -ti -n vault alpine -- cat /var/run/secrets/kubernetes.io/serviceaccount/token)
```
Authenticate from application pod to Vault using JWT
```
kubectl exec -ti -n vault alpine -- curl -k --request POST --data '{"jwt": "'$APP_POD_LOCAL_JWT'", "role": "test-role"}' http://vault-ui.vault.svc.cluster.local:8200/v1/auth/kubernetes/login
```
**TLS**
```
./k8s_auth-app-pod.sh
```
Export application pod service account token
```
APP_POD_LOCAL_JWT=$(kubectl exec -ti -n vault alpine -- cat /var/run/secrets/kubernetes.io/serviceaccount/token)
```
Authenticate from application pod to Vault using JWT
```
kubectl exec -ti -n vault alpine -- curl -k --request POST --data '{"jwt": "'$APP_POD_LOCAL_JWT'", "role": "test-role"}' https://vault-ui.vault.svc.cluster.local:8200/v1/auth/kubernetes/login
```

<!-- ### Kubernetes Auth Method with External Vault

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
``` -->

<!-- Get app pod local JWT
```
APP_POD_LOCAL_JWT=$(kubectl exec -ti -n vault alpine -- cat /var/run/secrets/kubernetes.io/serviceaccount/token)
```

Log into Vault using k8s auth from app pod
```
kubectl exec -ti -n vault alpine -- curl -vv --request POST --data '{"jwt": "'$APP_POD_LOCAL_JWT'", "role": "test-role"}' http://$MINIKUBE_HOST_IP:8200/v1/auth/kubernetes/login -->
<!-- ``` -->

## Replication

These scripts configure replication from the primary to secondary clusters.

Enable PR replication 
```
./performance-replication.sh
``` 
**TLS**
```
./performance-replication-tls.sh
```
Enable DR replication
```
./dr-replication.sh
``` 
**TLS**
```
./dr-replication-tls.sh
```

## Vault Agent

This script configures the Vault Agent and enables the postgres-<12345> application pod to read secrets rendered by the Vault Agent to a shared volume.

```
./vault-agent.sh
```
Check that secret was rendered in application pod
```
kubectl exec -ti postgres-<12345> -- cat /vault/secrets/password.txt
```
**TLS**
```
./vault-agent-tls.sh
```
Check that secret was rendered in application pod
```
kubectl exec -ti postgres-<12345> -- cat /vault/secrets/password.txt
```

### Vault Agent with Dynamic Postgres Credentials

This script configures the Vault Agent and enables the orgchart-<123> application pod to read secrets rendered by the Vault Agent to a shared volume that are dynamically updated in the postgres application pod.

```
./vault-agent-injector-dynamic-postgres-creds.sh
```
Check that credentials are automatically updated in application pod
```
kubectl exec -ti -n vault orgchart-<123> -- sh
```
Check database-creds.txt to see credentials update
```
watch -n 1 cat /vault/secrets/database-creds.txt
```
Check that credentials are renewed in Postgres application pod
```
kubectl exec -ti postgres -- sh
```
Run while loop to see credentials update
```
while :; do psql -U root -c "SELECT usename, valuntil FROM pg_user;"; sleep 1; done
```

### Configure Vault Agent with JWT auto-auth

This script configures the Vault Agent with JWT auto-auth and enables authentication from an postgres-<12345> application pod.

```
./vault-agent-jwt-auto-auth.sh
```
Check that config.json is rendered with JWT auth
```
kubectl exec -ti postgres-<12345> -c vault-agent -- cat /home/vault/config.json
```
**TLS**
```
./vault-agent-jwt-auto-auth_tls.sh
```
Check that config.json is rendered with JWT auth
```
kubectl exec -ti postgres-<12345> -c vault-agent -- cat /home/vault/config.json
```

## Vault Secrets Operator

This script configures the Vault Secrets Operator and syncs a Vault secret to a Kubernetes secret.

```
./vault-secrets-operator.sh
```
Retrieve k8s secret
```
kubectl get secret -n vso secretkv -o jsonpath="{.data.password}" | base64 --decode
```
**TLS**
```
./vault-secrets-operator_tls.sh
```
Retrieve k8s secret
```
kubectl get secret -n vso secretkv -o jsonpath="{.data.password}" | base64 --decode
```

## LDAP 

This script configures LDAP auth method and enables login to Vault via using credentials from an OpenLDAP server.

```
./ldap_auth.sh
```
Login using LDAP auth
```
kubectl exec -ti -n vault vault-0 -- vault login -method=ldap -path=ldap username="user01" password=password01
```
```

This script configures LDAP secrets engine and allows a user to request credentials for a role.

./ldap_secrets_engine.sh
```
Read credential
```
kubectl exec -ti -n vault vault-0 -- vault read ldap/static-cred/hashicorp-ldap
```

## App Role

This script configures AppRole auth method and allows a user to log into Vault using the role_id and secret_id to obtain a token.

```
./app-role.sh
```

# Sources

* https://developer.hashicorp.com/vault/docs/platform/k8s/helm/examples/standalone-tls
* https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-minikube-tls#create-the-certificate