This repo spins up a Vault Raft cluster in k8s with TLS enabled

Sources:

* https://developer.hashicorp.com/vault/docs/platform/k8s/helm/examples/standalone-tls
* https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-minikube-tls#create-the-certificate

Instructions: 

1. Start Minikube
`minikube start`

2. Initialize primary Vault
`./init-primary.sh`

3. Initialize secondary cluster 
`./init-secondary.sh`

Options:

1. Enable DR replication
   1. `./enable_dr.sh`

* Make sure to run the cleanup.sh script to remove old certs when creating a new lab







