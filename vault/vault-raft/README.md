# Prerequisites 

* A Kubernetes cluster
* [Helm](https://helm.sh/docs/intro/install/)
  * Can be installed using binary releases or package manager
* Minikube
* Docker
* `kubectl` CLI installed locally

# Install Vault Helm Chart

1. Start Minikube cluster
   1. `minikube start`
2. Add Vault license as a Kubernetes secret 
   1. `export VAULT_LICENSE="<license_string>"`
   2. `secret=$VAULT_LICENSE`
   3. `kubectl create secret generic vault-ent-license --from-literal="license=${secret}"`
3. Confirm Kubernetes secret has been added
   1. `kubectl get secret`
4. Update user-supplied values file (vault-values.yaml) to override the default values.yaml
5. Install Vault Helm chart
   1. `helm install vault hashicorp/vault --values vault-values.yaml --set "server.ha.replicas=3"`
6. Check that pods are up
   1. `kubectl get pods`
7. Once pods are running, run init script (init.sh) to initialize and unseal Vault and join nodes to the Raft cluster
   1. `./init.sh`    
8.  In another terminal, set up port forwarding to access UI
    1.  `kubectl port-forward vault-0 8200:8200`
    2.  Open http://127.0.0.1:8200 from a browser

# Cleanup

* Run cleanup script to cleanup k8s resources created by Helm chart and PVCs
  * `./cleanup.sh`

# Useful Commands

* Check Kubernetes resources that were created using Helm
  * `helm get manifest vault`
* Check PVCs
  * `kubectl get pvc`
* Check statefulsets
  * `kubectl get sts`
* Check configmap
  * `kubectl get configmap`
* Scale replicas
  * `kubectl scale statefulsets vault --replicas=<number_of_replicas>`
* List Helm releases
  * `helm list <name_of_release>`
* Get context to view k8s clusters
  * `kubectl config get-contexts`
* Set context to select k8s cluster to interact with
  * `kubectl config use-context minikube`

# References 
* https://developer.hashicorp.com/vault/docs/platform/k8s/helm/examples/ha-with-raft
* HashiCorp GitHub repo, docs.