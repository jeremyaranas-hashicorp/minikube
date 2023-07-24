# Create a namespace for the k8s secret
kubectl create ns app

# Set up k8s auth method for the secret
kubectl apply -f vault-auth-static.yaml

# Create the secret in the app namespace
kubectl apply -f static-secret.yaml