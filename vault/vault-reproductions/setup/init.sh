#!/usr/bin/env bash

echo "Enter Vault version (e.g. 1.15.2-ent): "
read VERSION
export VERSION=$VERSION

# Update values file with Vault version from input
envsubst < ../helm_chart_values_files/vault-values.yaml > ../helm_chart_values_files/vault-values-updated.yaml
envsubst < ../helm_chart_values_files/vault-consul-values.yaml > ../helm_chart_values_files/vault-consul-values-updated.yaml
envsubst < ../helm_chart_values_files/vault-values-auto-unseal.yaml > ../helm_chart_values_files/vault-values-auto-unseal-updated.yaml
envsubst < ../helm_chart_values_files/vault-values-secondary-tls.yaml > ../helm_chart_values_files/vault-values-secondary-tls-updated.yaml
envsubst < ../helm_chart_values_files/vault-values-secondary.yaml > ../helm_chart_values_files/vault-values-secondary-updated.yaml
envsubst < ../helm_chart_values_files/vault-values-tls.yaml > ../helm_chart_values_files/vault-values-tls-updated.yaml
envsubst < ../helm_chart_values_files/vault-values-transit.yaml > ../helm_chart_values_files/vault-values-transit-updated.yaml

# Show current list of config options
cat << EOF
Current Options
-----------------
1) Raft with auto-unseal (via Transit) 
2) Raft with Shamir
3) Consul with Shamir
4) Raft with Shamir and TLS [NEED TO FIX]
-----------------
EOF

echo "Enter an option (e.g. 1, 2, etc.): "
read OPTION

# Run script based on config options
if [[ $OPTION == "1" ]] 
then
    echo "INFO: Option 1 selected"
    ./transit-primary.sh
elif [[ $OPTION == "2" ]] 
then
    echo "INFO: Option 2 selected"
    ./raft-primary.sh  
elif [[ $OPTION == "3" ]] 
then
    echo "INFO: Option 3 selected"
    ./consul-primary.sh
elif [[ $OPTION == "4" ]] 
then
    echo "INFO: Option 4 selected"
    ./tls_cluster.sh
else
  echo "Not a valid option"
fi