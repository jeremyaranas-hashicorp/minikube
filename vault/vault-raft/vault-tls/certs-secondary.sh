# Export variables
export SERVICE=vault-tls-secondary
export NAMESPACE=vault-secondary
export SECRET_NAME=vault-tls-secondary
export TMPDIR=/tmp/vault-secondary
export CSR_NAME=vault-csr-secondary

mkdir -p /tmp/vault-secondary

# Create a key for Kubernetes to sign
openssl genrsa -out ${TMPDIR}/vault.key 2048

# Create a file with the following contents for the CSR
cat <<EOF >${TMPDIR}/csr.conf
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
[alt_names]
DNS.1 = ${SERVICE}
DNS.2 = ${SERVICE}.${NAMESPACE}
DNS.3 = ${SERVICE}.${NAMESPACE}.svc
DNS.4 = ${SERVICE}.${NAMESPACE}.svc.cluster.local
DNS.5 = vault-0.vault-internal
DNS.6 = vault-1.vault-internal
DNS.7 = vault-2.vault-internal
DNS.8 = vault-secondary-0.vault-secondary-internal
DNS.9 = vault-secondary-1.vault-secondary-internal
DNS.10 = vault-secondary-2.vault-secondary-internal
DNS.11 = vault-active.vault.svc.cluster.local


DNS.12 = *.vault-internal
DNS.13 = *.vault-internal.vault.svc.cluster.local
DNS.14 = *.vault
DNS.15 = *.vault-secondary-internal
DNS.16 = *.vault-secondary-internal.secondary.svc.cluster.local
DNS.17 = *.vault-secondary
DNS.18 = vault-active
DNS.19 = vault-active.*
DNS.20 = vault-active.*.svc
DNS.21 = vault-active.vault.svc.cluster.local  
DNS.22 = vault
DNS.23 = vault-secondary
DNS.24 = vault.vault-active
DNS.25 = secondary.vault-secondary-active
DNS.26 = vault-secondary-active
DNS.27 = vault-secondary-active.secondary.svc.cluster.local. 

DNS.28 = *.vault-secondary-internal
DNS.29 = *.vault-secondary-internal.secondary.svc.cluster.local
DNS.30 = *.vault-secondary
DNS.31 = *.vault-internal
DNS.32 = *.vault-internal.vault.svc.cluster.local
DNS.33 = *.vault
DNS.34 = vault-active
DNS.35 = vault-active.*
DNS.36 = vault-active.*.svc
DNS.37 = vault-active.*.svc.cluster.local
DNS.38 = vault
DNS.39 = vault-secondary-active.secondary.svc.cluster.local   
DNS.40 = vault.vault-active
DNS.41 = secondary.vault-secondary-active
DNS.42 = vault-secondary-active
DNS.43 = vault-active.vault.svc.cluster.local     
IP.1 = 127.0.0.1
EOF

# Create a CSR
openssl req -new -key ${TMPDIR}/vault.key \
    -subj "/O=system:nodes/CN=system:node:${SERVICE}.${NAMESPACE}.svc" \
    -out ${TMPDIR}/server.csr \
    -config ${TMPDIR}/csr.conf

# Create a file with the following contents to send to Kubernetes
cat <<EOF >${TMPDIR}/csr.yaml
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: ${CSR_NAME}
spec:
  groups:
  - system:authenticated
  request: $(cat ${TMPDIR}/server.csr | base64 | tr -d '\r\n')
  signerName: kubernetes.io/kubelet-serving
  usages:
  - digital signature
  - key encipherment
  - server auth
EOF

# Send the CSR to Kubernetes
kubectl create -f ${TMPDIR}/csr.yaml

# Approve the CSR in Kubernetes
kubectl certificate approve ${CSR_NAME}

# Retrieve the certificate
serverCert=$(kubectl get csr ${CSR_NAME} -o jsonpath='{.status.certificate}')

# Write the certificate to a file
echo "${serverCert}" | openssl base64 -d -A -out ${TMPDIR}/vault.crt

# Retrieve Kubernetes CA 
kubectl config view --raw --minify --flatten -o jsonpath='{.clusters[].cluster.certificate-authority-data}' | base64 -d > ${TMPDIR}/vault.ca

# Create namespace
kubectl create namespace ${NAMESPACE}

# Store the key, cert, and Kubernetes CA into Kubernetes secrets
kubectl create secret generic ${SECRET_NAME} \
    --namespace ${NAMESPACE} \
    --from-file=vault.key=${TMPDIR}/vault.key \
    --from-file=vault.crt=${TMPDIR}/vault.crt \
    --from-file=vault.ca=${TMPDIR}/vault.ca