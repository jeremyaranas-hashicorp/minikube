#!/usr/bin/env bash

kubectl apply -f ../manifests/postgres-config.yaml
kubectl apply -f ../manifests/postgres-pvc-pv.yaml
kubectl apply -f ../manifests/postgres-deployment.yaml 
kubectl apply -f ../manifests/postgres-service.yaml