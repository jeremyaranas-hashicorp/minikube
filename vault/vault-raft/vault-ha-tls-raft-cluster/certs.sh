#!/usr/bin/env bash

export SERVICE=vault-tls
export NAMESPACE=vault
export SECRET_NAME=vault-tls
export TMPDIR=/tmp/vault
export CSR_NAME=vault-csr
export HELMNAME=vault

mkdir -p /tmp/vault

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
DNS.1 = *.$HELMNAME-internal
DNS.2 = *.$HELMNAME-internal.$NAMESPACE.svc.cluster.local
DNS.3 = *.$NAMESPACE
DNS.4 = *.$NAMESPACE.svc.cluster.local
DNS.5 = $HELMNAME.$NAMESPACE.svc
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