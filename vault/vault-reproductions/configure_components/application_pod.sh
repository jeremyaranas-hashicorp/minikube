#!/usr/bin/env bash

kubectl apply -f ../manifests/application-pod.yaml

sleep 10

kubectl exec -it -n vault alpine -- sh -c "apk update && apk add curl openssl nmap-ncat"
