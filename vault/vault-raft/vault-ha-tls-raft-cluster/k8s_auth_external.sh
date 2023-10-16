# Set up Vault external to k8s apps

# Spin up Vault dev server locally
vault server -dev -dev-root-token-id root -dev-listen-address 0.0.0.0:8200

# Export VAULT_ADDR
export VAULT_ADDR='http://0.0.0.0:8200'

# Enable k8s auth
vault auth enable kubernetes

# Set ENV vars for k8s auth method config
TOKEN_REVIEW_JWT=$(kubectl get secret $VAULT_HELM_SECRET_NAME --output='go-template={{ .data.token }}' | base64 --decode)
KUBE_CA_CERT=$(kubectl config view --raw --minify --flatten --output='jsonpath={.clusters[].cluster.certificate-authority-data}' | base64 --decode)
KUBE_HOST=$(kubectl config view --raw --minify --flatten --output='jsonpath={.clusters[].cluster.server}')

# Write k8s auth method
vault write auth/kubernetes/config token_reviewer_jwt="$TOKEN_REVIEW_JWT" kubernetes_host="$KUBE_HOST" kubernetes_ca_cert="$KUBE_CA_CERT" issuer="https://kubernetes.default.svc.cluster.local" disable_local_ca_jwt="true"

# Create role for k8s auth
vault write auth/kubernetes/role/test-role \
        bound_service_account_names="vault,test-sa,default" \
        bound_service_account_namespaces="vault,vso" \
        policies=test-policy \
        ttl=24h

# Get Minikube host IP
minikube ssh
dig +short host.docker.internal
dig +short host.docker.internal | xargs -I{} curl -s http://{}:8200/v1/sys/seal-status

# Deploy app pod in k8s cluster (in this case, Vault pod is being used as app pod but k8s auth isn't configured in this Vault cluster in k8s)
./init-primary.sh

# Get POD JWT
POD_LOCAL_JWT=$(kubectl exec -ti -n vault vault-0 -- cat /var/run/secrets/kubernetes.io/serviceaccount/token)

# Log into Vault using k8s auth from k8s app pod
kubectl exec -ti -n vault vault-0 -- curl -vv --request POST --data '{"jwt": "'$POD_LOCAL_JWT'", "role": "test-role"}' http://192.168.65.2:8200/v1/auth/kubernetes/login
