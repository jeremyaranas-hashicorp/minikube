#!/usr/bin/env bash

source ../main/common.sh

kubectl apply -f ../manifests/postgres-app-pod-v2.yaml 

create_postgres_service_account