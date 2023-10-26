# Prerequisites 

* A Kubernetes cluster
* [Helm](https://helm.sh/docs/intro/install/)
  * Can be installed using binary releases or package manager
* Minikube
* Docker
* `kubectl` CLI installed locally

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