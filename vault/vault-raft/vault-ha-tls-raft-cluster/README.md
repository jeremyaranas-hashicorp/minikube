This repo spins up a Vault Raft cluster in k8s

Sources:

* https://developer.hashicorp.com/vault/docs/platform/k8s/helm/examples/standalone-tls
* https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-minikube-tls#create-the-certificate

Instructions: 

1. Start Minikube
   1. `minikube start`

2. Initialize primary cluster
   1. `./init-primary.sh`

3. Initialize secondary cluster
   1. `./init-secondary.sh`

Options:

1. Enable Performance Replication
   1. `./enable_pr.sh`
2. Enable Kubernetes Authentication Method
   1. `./enable_k8s_auth.sh`
      1. Test login using long-lived token from service account
         1. `SA_JWT=$(kubectl get secret test-sa -n vault -o go-template='{{ .data.token }}' | base64 --decode)`   
         2. `kubectl exec -ti -n vault vault-0 -- curl -k --request POST --data '{"jwt": "'$SA_JWT'", "role": "test-role"}' http://127.0.0.1:8200/v1/auth/kubernetes/login`
      2. Test login using local JWT from pod
         1. `POD_LOCAL_JWT=$(kubectl exec -ti -n vault vault-0 -- cat /var/run/secrets/kubernetes.io/serviceaccount/token)`
         2. `kubectl exec -ti -n vault vault-0 -- curl -k --request POST --data '{"jwt": "'$POD_LOCAL_JWT'", "role": "test-role"}' http://127.0.0.1:8200/v1/auth/kubernetes/login`
3. Enable Vault Secrets Operator
   1. `./enable_vso.sh`
      1. Retrieve k8s secret
         1. `kubectl get secret -n vso test-k8s-secret -o jsonpath="{.data.password}" | base64 --decode`
      2. Create a new secret 
         1. `./create_new_secret.sh`
      3. Check that k8s secret was updated
         1. `kubectl get secret -n vso test-k8s-secret -o jsonpath="{.data.password}" | base64 --decode`
4. Enable CSI
   1. `./enable_csi.sh`
      1. Check that secret exist in app pod 
         1. `kubectl exec -n vault nginx-deployment -- cat /mnt/secrets-store/test-object`
5. Enable VAI
   1. 
6. Enable TLS
   1. `./enable_tls.sh`
   2. Unseal each pod once pods start

TODO: Add VAI








