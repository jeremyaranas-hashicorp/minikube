# Upgrades

* Update Helm chart version
  * Install Vault Helm chart 
    * `helm install vault hashicorp/vault --version 0.21.0 --values vault-values.yaml` 
  * Initialize cluster
    * `./init.sh`
  * Check vault status
    * `kubectl exec -ti vault-0 -- vault status`
      * Vault version is set to version in vault-values.yaml even though chart 0.21.0 maps to app version 1.11.2
  * Check Helm chart version
    * `helm ls`
  * Update Helm chart version
    * `helm upgrade vault hashicorp/vault --version=0.22.1 --values vault-values.yaml` 
  * Check vault status
    * `kubectl exec -ti vault-0 -- vault status`
  * Set unseal key for unsealing rescheduled pods
    * `export VAULT_UNSEAL_KEY_CLUSTER_A=$(jq -r ".unseal_keys_b64[]" cluster-a-keys.json)`
  * Reschedule pods (always start with the standby pods, once standby pods have been rescheduled and unsealed, run `vault operator step-down` on the active pod to pass leadership, then reschedule active pod)
    * Reschedule vault-1
      * `kubectl delete pod vault-1`
    * Unseal vault-1
      * `kubectl exec -ti vault-1 -- vault operator unseal $VAULT_UNSEAL_KEY_CLUSTER_A`
    * Reschedule vault-2
      * `kubectl delete pod vault-2`
    * Unseal vault-2
      * `kubectl exec -ti vault-2 -- vault operator unseal $VAULT_UNSEAL_KEY_CLUSTER_A`
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
    * Unseal vault-0
      * `kubectl exec -ti vault-0 -- vault operator unseal $VAULT_UNSEAL_KEY_CLUSTER_A`
  * Check Helm chart version
    * `helm ls`
      * Notice that Helm chart version is updated but Vault version is set to version in vault-values.yaml even though chart 0.22.1 maps to app version 1.12.0
  
* Upgrade Vault via values override file 
  * Install Vault Helm chart
    * `helm install vault hashicorp/vault --values vault-values.yaml`
  * Run init script 
    * `./init.sh`
  * Check vault status to get version
    * `kubectl exec -ti vault-0 -- vault status`
  * Edit vault-values.yaml server.image.tag to 1.12.0-ent
  * Run Helm upgrade to deploy new version of Helm chart
    * `helm upgrade vault hashicorp/vault --values vault-values.yaml`
  * Check vault status
    * `kubectl exec -ti vault-0 -- vault status`
  * Set unseal key for unsealing rescheduled pods
    * `export VAULT_UNSEAL_KEY_CLUSTER_A=$(jq -r ".unseal_keys_b64[]" cluster-a-keys.json)`
  * Reschedule pods (always start with the standby pods, once standby pods have been rescheduled and unsealed, run `vault operator step-down` on the active pod to pass leadership, then reschedule active pod)
    * Reschedule vault-1
      * `kubectl delete pod vault-1`
    * Unseal vault-1
      * `kubectl exec -ti vault-1 -- vault operator unseal $VAULT_UNSEAL_KEY_CLUSTER_A`
    * Reschedule vault-2
      * `kubectl delete pod vault-2`
    * Unseal vault-2
      * `kubectl exec -ti vault-2 -- vault operator unseal $VAULT_UNSEAL_KEY_CLUSTER_A`
    * Confirm that vault-0 is active
      * `kubectl exec -ti vault-0 -- vault status`
    * Login to Vault
      * `kubectl exec -ti vault-0 -- vault login $(jq -r ".root_token" cluster-a-keys.json)`
    * Step down active node to transfer leadership
      * `kubectl exec -ti vault-0 -- vault operator step-down`
    * Confirm new leader
      * `kubectl exec -ti vault-0 -- vault status`
    * Reschedule vault-0
      * `kubectl delete pod vault-0`
    * Unseal vault-0
      * `kubectl exec -ti vault-0 -- vault operator unseal $VAULT_UNSEAL_KEY_CLUSTER_A`
  * Check vault status
    * `kubectl exec -ti vault-2 -- vault status`
      * Notice that version has been updated 
