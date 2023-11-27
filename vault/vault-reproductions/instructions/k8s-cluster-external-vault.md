Set up a Vault cluster with k8s auth and Kuberenetes cluster for application pods 

1. Start Minikube
   1. `minikube start`
2. Initialize primary cluster
   1. `cd` to **setup** directory
   2. `./init-primary.sh`
3. Deploy application pod
   1. `./application_pod.sh`
4. Spin up Vault server
   1. `vault server -dev -dev-root-token-id root`
5. Export VAULT_ADDR
   1. `export VAULT_ADDR='http://127.0.0.1:8200'`
6. Enable k8s auth 
   1. `vault auth enable kubernetes`
7. Set ENV vars for k8s auth method config
   1. `KUBE_CA_CERT=$(kubectl config view --raw --minify --flatten --output='jsonpath={.clusters[].cluster.certificate-authority-data}' | base64 --decode)`
   2. `KUBE_HOST=$(kubectl config view --raw --minify --flatten --output='jsonpath={.clusters[].cluster.server}')`
8. Set up k8s auth method
   1. `vault write auth/kubernetes/config kubernetes_host="$KUBE_HOST" kubernetes_ca_cert="$KUBE_CA_CERT" issuer="https://kubernetes.default.svc.cluster.local" disable_local_ca_jwt="true"`
9. Create role for k8s auth
   1. `vault write auth/kubernetes/role/test-role bound_service_account_names="vault,test-sa,default,postgres-service-account" bound_service_account_namespaces="vault,vso,default" policies=test-policy ttl=24h`
10. Get Minikube host IP and set ENV var
    1. `minikube ssh`
        1. `dig +short host.docker.internal`
        2. `exit`
    2. `MINIKUBE_HOST_IP=<IP>`
11. Create a ClusterRoleBinding 
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
1. Get app pod local JWT
    1. `APP_POD_LOCAL_JWT=$(kubectl exec -ti -n vault alpine -- cat /var/run/secrets/kubernetes.io/serviceaccount/token)`
2. Log into Vault using k8s auth from app pod
    1. `kubectl exec -ti -n vault alpine -- curl -vv --request POST --data '{"jwt": "'$APP_POD_LOCAL_JWT'", "role": "test-role"}' http://$MINIKUBE_HOST_IP:8200/v1/auth/kubernetes/login`
