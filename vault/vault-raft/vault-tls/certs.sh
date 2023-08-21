# Source https://developer.hashicorp.com/vault/docs/platform/k8s/helm/examples/standalone-tls

# Export variables
export SERVICE=vault-server-tls
export NAMESPACE=vault
export SECRET_NAME=vault-server-tls
export TMPDIR=/tmp
export CSR_NAME=vault-csr

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

# Create namespace
kubectl create namespace ${NAMESPACE}

# Store the key, cert, and Kubernetes CA into Kubernetes secrets
kubectl create secret generic ${SECRET_NAME} \
    --namespace ${NAMESPACE} \
    --from-file=vault.key=${TMPDIR}/vault.key \
    --from-file=vault.crt=${TMPDIR}/vault.crt \
    --from-file=vault.ca=${TMPDIR}/vault.ca