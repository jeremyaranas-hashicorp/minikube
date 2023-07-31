# Kubernetes Auth Method

1. Enable k8s auth method
   1. `./enable_k8s_auth.sh`
2. Test k8s auth method login using service account JWT
   1. `SA_JWT=$(kubectl get secret test-sa -n test-namespace -o go-template='{{ .data.token }}' | base64 --decode)`
   2. `kubectl exec -ti vault-0 -- curl --request POST --data '{"jwt": "'$SA_JWT'", "role": "test-role"}' http://127.0.0.1:8200/v1/auth/kubernetes/login`
3. Test k8s auth method login using local JWT from pod
   1. `POD_LOCAL_JWT=$(kubectl exec -ti vault-0 -- cat /var/run/secrets/kubernetes.io/serviceaccount/token)`
   2. `kubectl exec -ti vault-0 -- curl --request POST --data '{"jwt": "'$POD_LOCAL_JWT'", "role": "test-role"}' http://127.0.0.1:8200/v1/auth/kubernetes/login`

* Run cleanup script
  * `./cleanup.sh`