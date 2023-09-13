This repo spins up a Vault Raft cluster in k8s with TLS enabled

Sources:

* https://developer.hashicorp.com/vault/docs/platform/k8s/helm/examples/standalone-tls
* https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-minikube-tls#create-the-certificate

Instructions: 

1. Start Minikube
`minikube start`

2. Initialize primary Vault
`./init-primary.sh`

3. Initialize secondary cluster (for replication)
`./init-secondary.sh`

Options:

1. Enable PR replication
   1. `./enable_pr.sh`
2. Enable k8s auth
   1. `./enable_k8s_auth.sh`
      1. Test login using long-lived token from service account
         1. `SA_JWT=$(kubectl get secret test-sa -n vault -o go-template='{{ .data.token }}' | base64 --decode)`   
         2. `kubectl exec -ti -n vault vault-0 -- curl -k --request POST --data '{"jwt": "'$SA_JWT'", "role": "test-role"}' https://127.0.0.1:8200/v1/auth/kubernetes/login`
      2. Test login using local JWT from pod
         1. `POD_LOCAL_JWT=$(kubectl exec -ti -n vault vault-0 -- cat /var/run/secrets/kubernetes.io/serviceaccount/token)`
         2. `kubectl exec -ti -n vault vault-0 -- curl -k --request POST --data '{"jwt": "'$POD_LOCAL_JWT'", "role": "test-role"}' https://127.0.0.1:8200/v1/auth/kubernetes/login`

* Make sure to run the cleanup.sh script to remove old certs when creating a new lab







