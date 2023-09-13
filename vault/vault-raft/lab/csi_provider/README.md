# CSI Provider

1. Start a new Minikube cluster
   1. `minikube start -p <cluster_name>`
2. Set VAULT_LICENSE variable to license string in shell
3. . Deploy Vault Helm, set up CSI provider
   1. `./lab_setup.sh`

# Lab

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
   * kubectl describe pod webapp`
 
```
Warning  FailedMount  3s (x5 over 10s)  kubelet            MountVolume.SetUp failed for volume "secrets-store-inline" : kubernetes.io/csi: mounter.SetUpAt failed to get CSI client: driver name secrets-store.csi.k8s.io not found in the list of registered CSI drivers
```

4. Add CSI repo
   * `helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts`
5. Install CSI Helm chart
   * `helm install csi secrets-store-csi-driver/secrets-store-csi-driver --set syncSecret.enabled=true`
6. Scale webapp deployment
   * `kubectl scale deployment webapp --replicas=0`
   * `kubectl scale deployment webapp --replicas=1`
7. Check why webapp-pod isn't starting
   * `kubectl describe pod webapp`
   
```
Warning  FailedMount  0s (x4 over 4s)  kubelet            MountVolume.SetUp failed for volume "secrets-store-inline" : rpc error: code = Unknown desc = failed to get secretproviderclass default/vault-database, error: SecretProviderClass.secrets-store.csi.x-k8s.io "vault-database" not found
```

9. Create a secretProviderClass
   * `kubectl apply --filename SecretProviderClass.yaml`
10. Scale webapp deployment
   * `kubectl scale deployment webapp --replicas=0`
   * `kubectl scale deployment webapp --replicas=1`
11. Check why webapp-pod isn't starting
   * `kubectl describe pod webapp`
12. Scale webapp deployment
   * `kubectl scale deployment webapp --replicas=0`
   * `kubectl scale deployment webapp --replicas=1`
13. Check why webapp-pod isn't starting
   * `kubectl describe pod webapp`

```
Warning  FailedMount  4s (x5 over 12s)  kubelet            MountVolume.SetUp failed for volume "vault-db-creds" : rpc error: code = Unknown desc = failed to mount secrets store objects for pod default/webapp-569ffd55fb-fjl9q, err: rpc error: code = Unknown desc = error making mount request: failed to login: Error making API request.

URL: POST http://vault.default:8200/v1/auth/kubernetes/login
Code: 400. Errors:

* invalid role name "app"
```
14. Check role that is being used for k8s auth in Vault pod
   * `kubectl exec -ti vault-0 -- vault list auth/kubernetes/role`
15. Update role in SecretProviderClass to use role in k8s auth method
16. Re-create secretproviderclass
   * `kubectl replace --filename SecretProviderClass.yaml`
17. Scale webapp deployment
   * `kubectl scale deployment webapp --replicas=0`
   * `kubectl scale deployment webapp --replicas=1`
18. Check why webapp-pod isn't starting
   * `kubectl describe pod webapp`

```
URL: GET http://vault.default:8200/v1/database/data/secret
Code: 403. Errors:

* 1 error occurred:
* permission denied 
```

19. Check secrets path in Vault
   * `kubectl exec -ti vault-0 -- vault secrets list`
20. Update objects in SecretProviderClass to match path to secret in Vault
21. Re-create secretproviderclass
   * `kubectl replace --filename SecretProviderClass.yaml`
22. Scale webapp deployment
   * `kubectl scale deployment webapp --replicas=0`
   * `kubectl scale deployment webapp --replicas=1`
23. Display secret written to the file system on the pod
  * `kubectl exec <webapp> -- cat /mnt/secrets-store/test-object`


References:

https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-secret-store-driver
