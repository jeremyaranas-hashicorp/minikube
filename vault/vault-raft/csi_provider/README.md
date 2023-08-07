# CSI Provider

1. Start a new Minikube cluster
   1. `minikube start -p <cluster_name>`
2. . Deploy Vault Helm, set up CSI provider
   1. `./enable_csi.sh`
3. Display secret written to the file system on the pod
   1. `kubectl exec nginx-deployment -- cat /mnt/secrets-store/test-object`

* Run cleanup script
  * `./cleanup.sh`

References:

https://developer.hashicorp.com/vault/tutorials/kubernetes/kubernetes-secret-store-driver

