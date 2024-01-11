#!/usr/bin/env bash

./k8s_auth.sh
./postgresql_app_pod_v3.sh
./vault_agent_auto_auth.sh