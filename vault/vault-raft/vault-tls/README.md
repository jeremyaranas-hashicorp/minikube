This repo spins up a Vault node in k8s with TLS

1. Start Minikube
`minikube start`

2. Run 
`./certs.sh`

3. Init clusters
`./init.sh`

In another terminal window, forward port to view Vault in UI

`kubectl port-forward vault-0 -n vault 8200:8200`

Go to `https://127.0.0.1:8200` using a browser to confirm Vault UI has HTTPS



