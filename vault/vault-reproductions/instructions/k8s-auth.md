Set up Vault cluster with k8s auth

1. Start Minikube
   1. `minikube start`
2. Initialize primary cluster
   1. `cd` to **setup** directory
   2. `./init-primary.sh`
3. Enable Kubernetes Authentication Method
   1. cd to **configure_components**
   2. `./k8s_auth.sh`
      1. Test login using long-lived token from service account
         1. `SA_JWT=$(kubectl get secret test-secret -n vault -o go-template='{{ .data.token }}' | base64 --decode)`   
         2. `kubectl exec -ti -n vault vault-0 -- curl -k --request POST --data '{"jwt": "'$SA_JWT'", "role": "test-role"}' http://127.0.0.1:8200/v1/auth/kubernetes/login`
      2. Test login using local JWT from Vault pod
         1. `VAULT_POD_LOCAL_JWT=$(kubectl exec -ti -n vault vault-0 -- cat /var/run/secrets/kubernetes.io/serviceaccount/token)`
         2. `kubectl exec -ti -n vault vault-0 -- curl -k --request POST --data '{"jwt": "'$VAULT_POD_LOCAL_JWT'", "role": "test-role"}' http://127.0.0.1:8200/v1/auth/kubernetes/login`
      3. Deploy app pod to test k8s auth 
         1. `./k8s_auth-app-pod.sh`
            1. Export app pod local JWT
               1. `APP_POD_LOCAL_JWT=$(kubectl exec -ti -n vault alpine -- cat /var/run/secrets/kubernetes.io/serviceaccount/token)`
            2. Authenticate from app pod to Vault using local JWT
               1. `kubectl exec -ti -n vault alpine -- curl -k --request POST --data '{"jwt": "'$APP_POD_LOCAL_JWT'", "role": "test-role"}' http://vault-active.vault.svc.cluster.local:8200/v1/auth/kubernetes/login`