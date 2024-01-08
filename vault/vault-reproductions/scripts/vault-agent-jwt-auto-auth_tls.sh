#!/usr/bin/env bash

./k8s_auth.sh
./postgresql-app-pod-02-tls.sh
./postgresql-app-pod-03_tls.sh
./vault-agent-auto-auth.sh