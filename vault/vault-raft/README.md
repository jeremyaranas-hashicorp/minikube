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

# Other Scenarios

## Upgrades

* Update Helm chart version
  * Install Vault Helm chart 
    * `helm install vault hashicorp/vault --version 0.20.0 --values vault-values.yaml` 
  * Initialize cluster
    * `./init.sh`
  * Check `vault status`
    * `kubectl exec -ti vault-0 -- vault status`
      * Vault version is set to version in vault-values.yaml even though chart 0.20.0 maps to app version 1.10.3
  * Check Helm chart version
    * `helm ls`
  * Update Helm chart version
    * `helm upgrade vault hashicorp/vault --version=0.22.1 --values vault-values.yaml` 
  * Check `vault status`
    * `kubectl exec -ti vault-0 -- vault status`
  * Reschedule pods (always start with the standby pods, once standby pods have been rescheduled and unsealed, run `vault operator step-down` on the active pod to pass leadership, then reschedule active pod)
    * Reschedule vault-1
      * `kubectl delete pod vault-1`
    * Reschedule vault-2
      * `kubectl delete pod vault-2`
    * Confirm that vault-0 is active
      * `kubectl exec -ti vault-0 -- vault status`
    * Login to Vault
      * `kubectl exec vault-0 -- vault login $(jq -r ".root_token" cluster-a-keys.json)`
    * Step down active node to transfer leadership
      * `kubectl exec -ti vault-0 -- vault operator step-down`
    * Confirm new leader
      * `kubectl exec -ti vault-0 -- vault status`
    * Reschedule vault-0
    * `kubectl delete pod vault-0`
  * Check `vault status`
    * `kubectl exec -ti vault-2 -- vault status`
  * Check Helm chart version
    * `helm ls`
      * Notice that Helm chart version is updated but Vault version is set to version in vault-values.yaml even though chart 0.22.1 maps to app version 1.12.0
  
* Upgrading Vault via values override file 
  * Install Vault Helm chart
    * `helm install vault hashicorp/vault --values vault-values.yaml`
  * Run init script 
    * `./init.sh`
  * Check`vault status` to get version
    * `kubectl exec -ti vault-0 -- vault status`
  * Edit vault-values.yaml server.image.tag to 1.12.0-ent
  * Run Helm upgrade to deploy new version of Helm chart
    * `helm upgrade vault hashicorp/vault --values vault-values.yaml`
  * Check `vault status`
    * `kubectl exec -ti vault-0 -- vault status`
  * Reschedule pods (always start with the standby pods, once standby pods have been rescheduled and unsealed, run `vault operator step-down` on the active pod to pass leadership, then reschedule active pod)
    * Reschedule vault-2
      * `kubectl delete pod vault-2`
    * Reschedule vault-3
      * `kubectl delete pod vault-3`
    * Confirm that vault-0 is active
      * `kubectl exec -ti vault-0 -- vault status`
    * Login to Vault
      * `kubectl exec vault-0 -- vault login $(jq -r ".root_token" cluster-a-keys.json)`
    * Step down active node to transfer leadership
      * `kubectl exec -ti vault-0 -- vault operator step-down`
    * Confirm new leader
      * `kubectl exec -ti vault-0 -- vault status`
    * Reschedule vault-0
    * `kubectl delete pod vault-0`
  * Check `vault status`
    * `kubectl exec -ti vault-2 -- vault status`
      * Notice that version has been updated 
  
  Note that when a pod is rescheduled, it will need to be unsealed.
    
## Enabling Replication (PR)

* Run replication script to enable replication and generate secondary activation token on primary, and enable replication on secondary
  * `./enable_pr.sh`
* Check replication status
  * `kubectl exec -ti vault-0 -- vault read sys/replication/status -format=json`
  * `kubectl exec -ti vault-3 -- vault read sys/replication/status -format=json`

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
* Get context
  * `kubectl config get-contexts`
* Set context
  * `kubectl config use-context minikube`

# References 
* https://developer.hashicorp.com/vault/docs/platform/k8s/helm/examples/ha-with-raft
* HashiCorp GitHub repo, docs.
