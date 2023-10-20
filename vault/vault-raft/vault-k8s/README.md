This repo spins up a Vault Raft cluster in k8s using the Vault Helm chart.

Sources:

* https://developer.hashicorp.com/vault/docs/platform/k8s/helm/examples/standalone-tls
* https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-minikube-tls#create-the-certificate

Instructions: 

1. Start Minikube
   1. `minikube start`

2. Initialize primary cluster
   1. `cd` to **setup** directory
   2. `./init-primary.sh`

3. Initialize secondary cluster (optional)
   1. `cd` to **setup** directory
   2. `./init-secondary.sh`

Options:

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
   1. `./jwt_auth.sh`
6. Enable Vault Agent Injector (requires jwt_auth.sh) 
   1. `./vai.sh`
      1. Check that secret exist in app pod
         1. `kubectl exec -ti -n vault web-app-<pod> -- cat /vault/secrets/password.txt`
      2. Check that auto_auth was configured in app pod for k8s auth (requires updating app.yaml annotations for k8s auth auto-auth)
         1. `kubectl exec -ti -n vault web-app-<pod> -c vault-agent -- sh`
         2. `cat /home/vault/config.json`
      3. Check that auto_auth was configured in app pod for jwt auth (requires updating app.yaml annotations for jwt auth auto-auth)
         1. `kubectl exec -ti -n vault web-app-<pod> -c vault-agent -- sh`
         2. `cat /home/vault/config.json`
7. Enable TLS
   1. `cd` to **tls** directory
   2. `./enable_tls.sh`
   3. Unseal each pod once pods start

# TO:DO

Create if statement to check if VSO namespace exist
Create if statement to check if VSO Helm chart is already installed 
Create if statement to check if CSI Helm chart is already installed
Move `vault auth enable kubernetes` outside of configure_k8s_auth function and create if statement to check if k8s auth is already enabled