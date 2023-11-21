#!/usr/bin/env bash

./k8s_auth.sh
./postgresql-app-pod-jwt-auto-auth.sh
./jwt_auth_vault_agent_auto_auth.sh

