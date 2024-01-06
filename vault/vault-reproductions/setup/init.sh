#!/usr/bin/env bash

echo "Enter Vault version (e.g. 1.15.2-ent):"
read VERSION
export VERSION=$VERSION

envsubst < ../helm_chart_values_files/vault-values.yaml > ../helm_chart_values_files/vault-values-updated.yaml
envsubst < ../helm_chart_values_files/vault-consul-values.yaml > ../helm_chart_values_files/vault-consul-values-updated.yaml
envsubst < ../helm_chart_values_files/vault-values-auto-unseal.yaml > ../helm_chart_values_files/vault-values-auto-unseal-updated.yaml
envsubst < ../helm_chart_values_files/vault-values-secondary-tls.yaml > ../helm_chart_values_files/vault-values-secondary-tls-updated.yaml
envsubst < ../helm_chart_values_files/vault-values-secondary.yaml > ../helm_chart_values_files/vault-values-secondary-updated.yaml
envsubst < ../helm_chart_values_files/vault-values-tls.yaml > ../helm_chart_values_files/vault-values-tls-updated.yaml
envsubst < ../helm_chart_values_files/vault-values-transit.yaml > ../helm_chart_values_files/vault-values-transit-updated.yaml


cat << EOF
Current Options
-----------------

1) Raft with auto-unseal (via Transit)
2) Raft with Shamir
3) Consul with Shamir

-----------------

EOF

echo "Enter storage backed (raft/consul):"
read BACKEND

echo "Enter unseal method (transit/shamir):"
read SEAL

if [[ $BACKEND == "raft" ]] && [[ $SEAL == "transit" ]]
then
    ./transit-primary.sh
elif [[ $BACKEND == "raft" ]] && [[ $SEAL == "shamir" ]]
then
    ./raft-primary.sh
elif [[ $BACKEND == "consul" ]] && [[ $SEAL == "shamir" ]]
then
    ./consul-primary.sh
else
  echo "Not a valid scenario."
fi