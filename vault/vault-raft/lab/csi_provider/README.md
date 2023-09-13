# Prereqs

* Clone repo from [vault/vault-raft/lab/csi_provider](https://github.com/jeremyaranas-hashicorp/minikube/tree/main/vault/vault-raft/lab/csi_provider)
* Set `VAULT_LICENSE` variable to license string in shell
* cd to vault/vault-raft/lab/csi_provider
* Run `./lab_setup.sh`

# Steps

1. Upgrade Vault Helm to include CSI pod
   * `helm upgrade vault hashicorp/vault -f vault-values.yaml --set csi.enabled=true --set injector.enabled=false`
2. Create app to use CSI secret store volume
   * `kubectl apply -f Deployment-csi.yaml`
3. Check why webapp-pod isn't starting
   * `kubectl describe pod webapp`
4. Add CSI repo
   * `helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts`
5. Install CSI Helm chart
   * `helm install csi secrets-store-csi-driver/secrets-store-csi-driver --set syncSecret.enabled=true`
6. Scale webapp deployment
   * `kubectl scale deployment webapp --replicas=0`
   * `kubectl scale deployment webapp --replicas=1`
7. Check why webapp-pod isn't starting
   * `kubectl describe pod webapp`
8. Create a secretProviderClass
   * `kubectl apply --filename SecretProviderClass.yaml`
9. Scale webapp deployment
   * `kubectl scale deployment webapp --replicas=0`
   * `kubectl scale deployment webapp --replicas=1`
10. Check why webapp-pod isn't starting
   * `kubectl describe pod webapp`
11. Check role that is being used for k8s auth in Vault pod
   * `kubectl exec -ti vault-0 -- vault list auth/kubernetes/role`
12. Update role in SecretProviderClass to use role in k8s auth method
13. Re-create secretproviderclass
   * `kubectl replace --filename SecretProviderClass.yaml`
14. Scale webapp deployment
   * `kubectl scale deployment webapp --replicas=0`
   * `kubectl scale deployment webapp --replicas=1`
15. Check why webapp-pod isn't starting
   * `kubectl describe pod webapp`
16. Check secrets path in Vault
   * `kubectl exec -ti vault-0 -- vault secrets list`
17. Update objects in SecretProviderClass to match path to secret in Vault
18. Re-create secretproviderclass
   * `kubectl replace --filename SecretProviderClass.yaml`
19. Scale webapp deployment
   * `kubectl scale deployment webapp --replicas=0`
   * `kubectl scale deployment webapp --replicas=1`
20. Display secret written to the file system on the pod
  * `kubectl exec <webapp> -- cat /mnt/secrets-store/test-object`
