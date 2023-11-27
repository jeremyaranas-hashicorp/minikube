Set up Vault Raft cluster in k8s with replication

1. Start Minikube
   1. `minikube start`
2. Initialize primary cluster
   1. `cd` to **setup** directory
   2. `./init-primary.sh`
3. Initialize secondary cluster 
   1. `./init-secondary.sh`
4. Enable replication 
   1. cd to **configure_components**
   2. `./performance-replication.sh` or `./dr-replication.sh` 