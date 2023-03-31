This repo spins up a Vault node in k8s with TLS
1. Start Minikube

`minikube start`

2. Run `./certs.sh`
3. Install Vault

`helm install -n vault-namespace vault hashicorp/vault --values helm-vault-values.yml`

4. Check that vault-0 is running

`k get pods -n vault-namespace`

5. Init clusters
`./init.sh`

6. Login to vault-0
`kubectl exec --stdin=true --tty=true vault-0 -n vault-namespace -- /bin/sh`

7. In another terminal window, forward port to view Vault in UI

`kubectl port-forward vault-0 -n vault-namespace 8200:8200`

8. Go to `https://127.0.0.1:8200` using a browser to confirm Vault UI has HTTPS



