# CSI Provider

1. Start a new Minikube cluster
   1. `minikube start -p <cluster_name>`
2. Set VAULT_LICENSE variable to license string in shell
3. . Deploy Vault Helm, set up CSI provider
   1. `./lab_setup.sh`

# Lab

1. Upgrade Vault Helm to include CSI pod
   1. `helm upgrade vault hashicorp/vault -f vault-values.yaml --set csi.enabled=true --set injector.enabled=false`
2. Create app to use CSI secret store volume
   1. `kubectl apply -f Deployment-csi.yaml`
3. Check why webapp-pod isn't starting
   1. `kubectl describe pod webapp`
   
   ```
   Warning  FailedMount  3s (x5 over 10s)  kubelet            MountVolume.SetUp failed for volume "secrets-store-inline" : kubernetes.io/csi: mounter.SetUpAt failed to get CSI client: driver name secrets-store.csi.k8s.io not found in the list of registered CSI drivers
   ```

4. Add CSI repo
   1. `helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts`
5. Install CSI Helm chart
   1. `helm install csi secrets-store-csi-driver/secrets-store-csi-driver --set syncSecret.enabled=true`
6. Scale webapp deployment
   1. `kubectl scale deployment webapp --replicas=0`
   2. `kubectl scale deployment webapp --replicas=1`
7. Check why webapp-pod isn't starting
   1. `kubectl describe pod webapp`
   
   ```
   Warning  FailedMount  0s (x4 over 4s)  kubelet            MountVolume.SetUp failed for volume "secrets-store-inline" : rpc error: code = Unknown desc = failed to get secretproviderclass default/vault-database, error: SecretProviderClass.secrets-store.csi.x-k8s.io "vault-database" not found
   ```

8. Create a secretProviderClass
   1. `kubectl apply --filename SecretProviderClass.yaml`
9. Check why webapp-pod isn't starting
   1. `kubectl describe pod webapp`
10. Update secretProviderClass in webapp-pod.yaml to match secretProviderClass name in SecretProviderClass.yaml
11. Scale webapp deployment
   1. `kubectl scale deployment webapp --replicas=0`
   2. `kubectl scale deployment webapp --replicas=1`
12. Check why webapp-pod isn't starting
    1.  `kubectl describe pod webapp`
    
   ```
   Warning  FailedMount  1s (x6 over 17s)  kubelet            MountVolume.SetUp failed for volume "vault-db-creds" : rpc error: code = Unknown desc = failed to mount secrets store objects for pod default/webapp-58b6fb576d-sldhx, err: rpc error: code = Unknown desc = error making mount request: failed to login: Error making API request.
   Code: 400. Errors:

   * invalid role name "app"
   ```

1. Check role that is being used for k8s auth in Vault pod
   1.  `kubectl exec -ti vault-0 -- vault list auth/kubernetes/role`
2. Update role in SecretProviderClass to use role in k8s auth method
3. Re-create secretproviderclass
   1.  `kubectl delete secretproviderclass vault-db-creds`
   2.  `kubectl apply --filename SecretProviderClass.yaml`
4. Scale webapp deployment
   1. `kubectl scale deployment webapp --replicas=0`
   2. `kubectl scale deployment webapp --replicas=1`
5. Check why webapp-pod isn't starting
   1.  `kubectl describe pod webapp`

   ```
   URL: GET http://vault.default:8200/v1/database/data/secret
   Code: 403. Errors:

   * 1 error occurred:
   * permission denied 
   ```

6. Check secrets path in Vault
   1. `kubectl exec -ti vault-0 -- vault secrets list`
7. Update objects in SecretProviderClass to match path to secret in Vault
8. Re-create secretproviderclass
   1. `kubectl delete secretproviderclass vault-db-creds`
   2. `kubectl apply --filename SecretProviderClass.yaml`
9. Scale webapp deployment
   1. `kubectl scale deployment webapp --replicas=0`
   2. `kubectl scale deployment webapp --replicas=1`
10. Display secret written to the file system on the pod
   1. `kubectl exec <webapp> -- cat /mnt/secrets-store/test-object`

* Run cleanup script
  * `./cleanup.sh`

References:

https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-secret-store-driver
