#!/usr/bin/env bash

./k8s_auth.sh
./postgresql-app-pod-03.sh
./vault-agent-auto-auth.sh