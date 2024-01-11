#!/usr/bin/env bash

./k8s_auth.sh
./postgresql_app_pod_v2_tls.sh
./postgresql_app_pod_v3_tls.sh
./vault_agent_auto_auth.sh