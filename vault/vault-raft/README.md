# Prerequisites 
* A Kubernetes cluster
* [Helm](https://helm.sh/docs/intro/install/)
  * Can be installed using binary releases or package manager
* Minikube
* Docker
* `kubectl` CLI installed locally

Note: This lab uses a Minikube Kubernetes cluster

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
   1. `helm install vault hashicorp/vault --values vault-values.yaml`
6. Check that pods are up
   1. `kubectl get pods`
7. Once pods are running, run init script (init.sh) to initialize and unseal Vault and join nodes to the Raft cluster
   1. `./init.sh`    
8. Check vault status on vault-0
   1. `kubectl exec vault-0 -- vault status`
9.  Login to vault-0 
   1.  `kubectl exec vault-0 -- vault login $(jq -r ".root_token" cluster-a-keys.json)`
10. Check vault-0 Raft status
    1.  `kubectl exec vault-0 -- vault operator raft list-peers`
11. Check vault status on vault-3
    1.  `kubectl exec vault-3 -- vault status`
12. Login to vault-3
    1.  `kubectl exec vault-3 -- vault login $(jq -r ".root_token" cluster-b-keys.json)`
13. Check vault-3 Raft status
    1.  `kubectl exec vault-3 -- vault operator raft list-peers`
14. In another terminal, set up port forwarding to access UI
    1.  `kubectl port-forward vault-0 8200:8200`
    2.  Open http://127.0.0.1:8200 from a browser

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

# Cleanup

1. Uninstall Vault Helm chart
   1. `helm uninstall vault`
2. Remove PVCs
   1. `kubectl delete pvc data-vault-0 data-vault-1 data-vault-2  data-vault-3 data-vault-4 data-vault-5`

# References 
* https://developer.hashicorp.com/vault/docs/platform/k8s/helm/examples/ha-with-raft
* HashiCorp GitHub repo, docs.

# Other Scenarios

* Upgrading Vault via Helm chart version
  * `helm install vault hashicorp/vault --version 0.21.0` 
  * `kubectl exec -ti vault-0 -- vault status`
    * Vault version 1.11.2
  * `helm upgrade vault hashicorp/vault --version=0.22.1` 
  * `kubectl exec -ti vault-0 -- vault status`
    * Vault version 1.11.2
  * `kubectl delete pod vault-0`
  * `kubectl exec -ti vault-0 -- vault status`
    * Vault version 1.12.0
* Upgrading Vault via values override file
  * `helm install vault hashicorp/vault --values vault-values.yaml`
  * `kubectl exec -ti vault-0 -- vault status`
    * Vault version 1.11.2
  * Edit vault-values.yaml server.image.tag to 1.12.0-ent
  * `helm upgrade vault hashicorp/vault --values vault-values.yaml`
  * `kubectl exec -ti vault-0 -- vault status`
    * Vault version 1.11.2
  * `kubectl delete pod vault-0`
  * `kubectl exec -ti vault-0 -- vault status`
    * Vault version 1.12.0


