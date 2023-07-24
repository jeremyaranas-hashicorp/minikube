# Login to Vault
kubectl exec -ti vault-0 -- vault login $(jq -r ".root_token" cluster-a-keys.json)

# Set a secret in Vault
kubectl exec -ti vault-0 -- vault secrets enable -path secret kv-v2
kubectl exec -ti vault-0 -- vault kv put secret/db-pass password="db-secret-password"

# Configure k8s auth
kubectl exec -ti vault-0 -- vault auth enable kubernetes

# Configure k8s auth method to use the location of the k8s API
kubectl exec -ti vault-0 -- vault write auth/kubernetes/config \
      kubernetes_host="https://10.96.0.1:443"

# Create a policy to give service account permission to read kv secret
kubectl exec -ti vault-0 -- vault policy write internal-app - <<EOF
path "secret/data/db-pass" {
  capabilities = ["read"]
}
EOF

# Create k8s auth role that binds Vault policy with k8s service account
kubectl exec -ti vault-0 -- vault write auth/kubernetes/role/database \
    bound_service_account_names=webapp-sa \
    bound_service_account_namespaces=default \
    policies=internal-app \
    ttl=20m

# Install secrets store CSI driver
helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts
helm install csi secrets-store-csi-driver/secrets-store-csi-driver \
    --set syncSecret.enabled=true

# Define a SecretProviderClass resource that describes parameters given to the CSI provider
cat > spc-vault-database.yaml <<EOF
apiVersion: secrets-store.csi.x-k8s.io/v1
kind: SecretProviderClass
metadata:
  name: vault-database
spec:
  provider: vault
  parameters:
    vaultAddress: "http://vault.default:8200"
    roleName: "database"
    objects: |
      - objectName: "db-password"
        secretPath: "secret/data/db-pass"
        secretKey: "password"
EOF

# Create the SecretProviderClass
kubectl apply --filename spc-vault-database.yaml

# Create sa 
kubectl create serviceaccount webapp-sa

# Define pod that mounts the secrets volume
cat > webapp-pod.yaml <<EOF
kind: Pod
apiVersion: v1
metadata:
  name: webapp
spec:
  serviceAccountName: webapp-sa
  containers:
  - image: jweissig/app:0.0.1
    name: webapp
    volumeMounts:
    - name: secrets-store-inline
      mountPath: "/mnt/secrets-store"
      readOnly: true
  volumes:
    - name: secrets-store-inline
      csi:
        driver: secrets-store.csi.k8s.io
        readOnly: true
        volumeAttributes:
          secretProviderClass: "vault-database"
EOF

# Create pod
kubectl apply --filename webapp-pod.yaml

# Display secret written to the file system on the pod
kubectl exec webapp -- cat /mnt/secrets-store/db-password