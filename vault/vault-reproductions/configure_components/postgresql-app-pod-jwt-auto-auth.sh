#!/usr/bin/env bash

kubectl apply -f ../manifests/postgres_auto-auth.yaml 

# Create service account and clusterrolebindings for postgres pod
source ../main/common.sh
create_postgres-service-account
