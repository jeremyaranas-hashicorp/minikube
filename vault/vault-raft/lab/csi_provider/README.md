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
   1. `kubectl apply --filename webapp-pod.yaml`
3. Check why webapp-pod isn't starting
   1. `kubectl describe pod webapp`
4. Add CSI repo
   1. `helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts`
5. Install CSI Helm chart
   1. `helm install csi secrets-store-csi-driver/secrets-store-csi-driver --set syncSecret.enabled=true`
6. Reschedule webapp-pod
   1. `kubectl delete pod webapp`
   2. `kubectl apply --filename webapp-pod.yaml`
7. Check why webapp-pod isn't starting
   1. `kubectl describe pod webapp`
8. Create a secretProviderClass
   1. `kubectl apply --filename SecretProviderClass.yaml`
9. Check why webapp-pod isn't starting
   1. `kubectl describe pod webapp`
10. Update secretProviderClass in webapp-pod.yaml to match secretProviderClass name in SecretProviderClass.yaml
11. Reschedule webapp-pod
   1. `kubectl delete pod webapp`
   2. `kubectl apply --filename webapp-pod.yaml`
12. Check why webapp-pod isn't starting
    1.  `kubectl describe pod webapp`
13. Check role that is being used for k8s auth in Vault pod
    1.  `kubectl exec -ti vault-0 -- vault list auth/kubernetes/role`
14. Update role in SecretProviderClass to use role in k8s auth method
15. Re-create secretproviderclass
    1.  `kubectl delete secretproviderclass vault-db-creds`
    2.  `kubectl apply --filename SecretProviderClass.yaml`
16. Reschedule webapp-pod
   1. `kubectl delete pod webapp`
   2. `kubectl apply --filename webapp-pod.yaml`
17. Check why webapp-pod isn't starting
    1.  `kubectl describe pod webapp`
18. Check secrets path in Vault
    1.  `kubectl exec -ti vault-0 -- vault secrets list`
19. Update objects in SecretProviderClass to match path to secret in Vault
20. Re-create secretproviderclass
    1.  `kubectl delete secretproviderclass vault-db-creds`
    2.  `kubectl apply --filename SecretProviderClass.yaml`
21. Reschedule webapp-pod
   1. `kubectl delete pod webapp`
   2. `kubectl apply --filename webapp-pod.yaml`
22. Display secret written to the file system on the pod
   1. `kubectl exec webapp -- cat /mnt/secrets-store/test-object`

* Run cleanup script
  * `./cleanup.sh`

References:

https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-secret-store-driver
