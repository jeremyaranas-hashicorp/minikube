#!/usr/bin/env bash

# Enable TLS

rm -fr /tmp/vault
./certs.sh
helm upgrade vault hashicorp/vault -f vault-values-tls.yaml -n vault
kubectl delete pod -n vault vault-0
kubectl delete pod -n vault vault-1
kubectl delete pod -n vault vault-2

rm -fr /tmp/vault-secondary
./certs-secondary.sh
helm upgrade vault-secondary hashicorp/vault -f vault-values-secondary-tls.yaml -n vault-secondary
kubectl delete pod -n vault-secondary vault-secondary-0
kubectl delete pod -n vault-secondary vault-secondary-1
kubectl delete pod -n vault-secondary vault-secondary-2