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


echo "Create secondary cluster? (e.g. yes/no): "
read SECONDARY


# Show current list of config options
cat << EOF
Current Options
-----------------
1) Vault cluster, Raft storage, Transit auto-unseal
2) Vault cluster, Raft storage, Shamir unseal
3) Vault cluster, Raft storage, Shamir unseal, TLS
4) Vault cluster, Consul storage, Shamir unseal
-----------------
EOF

echo "Enter an option (e.g. 1, 2, 3, 4): "
read OPTION

if [[ $OPTION == "1" ]] && [[ $SECONDARY == "yes" ]] # TESTED (YES/NO) YES with ./performance-replication.sh

then
     echo "INFO: Creating Vault primary and secondary clusters using Raft storage backend with Transit auto-unseal."
    ./transit-primary.sh
    ./raft-secondary.sh
elif [[ $OPTION == "1" ]] && [[ $SECONDARY == "no" ]] # TESTED (YES/NO) YES with ./vault-agent.sh
then 
    echo "INFO: Creating Vault primary cluster using Raft storage backend with Transit auto-unseal."
    ./transit-primary.sh

elif [[ $OPTION == "2" ]] && [[ $SECONDARY == "yes" ]] # TESTED (YES/NO) YES with ./performance-replication.sh
then 
    echo "INFO: Creating Vault primary and secondary clusters using Raft storage backend with Shamir unseal."
    ./raft-primary.sh
    ./raft-secondary.sh
elif [[ $OPTION == "2" ]] && [[ $SECONDARY == "no" ]] # TESTED (YES/NO) YES with ./vault-agent.sh
then 
    echo "INFO: Creating Vault primary cluster using Raft storage backend with Shamir unseal."
    ./raft-primary.sh

elif [[ $OPTION == "3" ]] && [[ $SECONDARY == "yes" ]] # TESTED (YES/NO) YES with ./performance-replication-tls.sh
then 
    echo "INFO: Creating Vault primary and secondary clusters using Raft storage backend, Transit auto-unseal and TLS."
    ./tls_primary.sh
    ./tls_secondary.sh
elif [[ $OPTION == "3" ]] && [[ $SECONDARY == "no" ]] # TESTED (YES/NO) YES with ./vault-agent-tls.sh
then 
    echo "INFO: Creating Vault primary cluster using Raft storage backend, Transit auto-unseal and TLS."
    ./tls_primary.sh

elif [[ $OPTION == "4" ]] && [[ $SECONDARY == "yes" ]] # TESTED (YES/NO) YES with ./performance-replication.sh
then 
    echo "INFO: Creating Vault primary cluster using Consul storage backend with Shamir unseal and Vault secondary cluster using Raft storage backend with Shamir unseal."
    ./consul-primary.sh
    ./raft-secondary.sh
elif [[ $OPTION == "4" ]] && [[ $SECONDARY == "no" ]] # TESTED (YES/NO) YES with ./vault-agent.sh
then 
    echo "INFO: Creating Vault primary cluster using Consul storage backend with Shamir unseal."
    ./consul-primary.sh
else
  echo "INFO: Not a valid option."
fi
