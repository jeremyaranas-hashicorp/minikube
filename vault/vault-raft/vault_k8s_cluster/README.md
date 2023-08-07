# Vault Kubernetes Cluster

1. Start a new Minikube cluster
   1. `minikube start -p <cluster_name>`
2. Update user-supplied values file (vault-values.yaml) to override the default values.yaml
3. Install Vault Helm chart
   1. `helm install vault hashicorp/vault --values vault-values.yaml`
4. Run init script to initialize and unseal Vault and join nodes to the Raft cluster
   1. `./init.sh`    
5.  In another terminal, set up port forwarding to access UI
    1.  `kubectl port-forward vault-0 8200:8200`
    2.  Open http://127.0.0.1:8200 from a browser

* Run cleanup script
  * `./cleanup.sh`

