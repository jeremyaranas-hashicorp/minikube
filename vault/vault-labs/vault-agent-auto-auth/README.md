This is a lab on setting up Vault Agent auto-auth using the JWT auth method.

# Set up lab

1. Start minikube
`minikube start`
2. Install Vault Helm
`./init-primary.sh`
3. Install prerequisites
`./prereqs.sh`

# Set up JWT auth method

The following steps are based on the instructions found in this HashiCorp [doc](https://developer.hashicorp.com/vault/docs/auth/jwt/oidc-providers/kubernetes).

1. Create a role binding that grants permissions defined in a role to a set of users for OIDC discovery URLs 
```
kubectl create clusterrolebinding oidc-reviewer  \
   --clusterrole=system:service-account-issuer-discovery \
   --group=system:unauthenticated
```
2. Get the issuer URL. This is the URL of the provider that allows the API server to discover public signing keys (public and private key pairs).
```
ISSUER="$(kubectl get --raw /.well-known/openid-configuration | jq -r '.issuer')"
```
3. Enable and configure JWT auth method 
`kubectl exec -n vault vault-0 -- vault auth enable jwt`
```
kubectl exec -n vault vault-0 -- vault write auth/jwt/config \
   oidc_discovery_url=https://kubernetes.default.svc.cluster.local \
   oidc_discovery_ca_pem=@/var/run/secrets/kubernetes.io/serviceaccount/ca.crt
```
4. Find the default audience
`kubectl create token default | cut -f2 -d. | base64 --decode`
5. Create role for JWT auth method for app pod
```
kubectl exec -ti -n vault vault-0 -- vault write auth/jwt/role/test-role \
   role_type="jwt" \
   bound_audiences="https://kubernetes.default.svc.cluster.local" \
   user_claim="sub" \
   bound_subject="system:serviceaccount:vault:test-sa" \
   policies="test-policy" \
   ttl="1h"
```

# Deploy application pod to use auto-auth

1. Deploy application pod to use Vault Agent auto-auth
`kubectl apply --filename app.yaml`
2. Check application pod
`kubectl get pods -n vault`
3. web-app-<pod> should show a CrashLoopBackOff
4. Check the vault-agent-init container logs to see why the container didn't start
`kubectl logs -n vault web-app-<pod> vault-agent-init`
5. An error should show `Error creating jwt auth method: missing 'path' value`
6. Update annotations in app.yaml to set the path for the JWT auto-auth
   1. Add this line 
      1. `vault.hashicorp.com/auth-config-path: /var/run/secrets/kubernetes.io/serviceaccount/token`
7. Re-deploy application pod
`kubectl apply --filename app.yaml`
8. Check application pod
`kubectl get pods -n vault`
9. web-app-<pod> should show as READY
10. Check app pod to see if auto-auth config was rendered
`kubectl exec -ti -n vault web-app-<pod> -c vault-agent -- sh`
`cd /home/vault`
`cat config.json`
11. The config.json shows the auth method configured for auto-auth and the sink location for the token

# References
[JWT auto-auth parameters](https://developer.hashicorp.com/vault/docs/agent-and-proxy/autoauth/methods/jwt)
[Vault Injector annotations](https://developer.hashicorp.com/vault/docs/platform/k8s/injector/annotations)
[ConfigMap example](https://developer.hashicorp.com/vault/docs/platform/k8s/injector/examples#configmap-example)