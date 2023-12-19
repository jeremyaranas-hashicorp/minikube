#!/usr/bin/env bash

source ../main/common.sh

helm install vault hashicorp/vault --values ../helm_chart_value_files/vault-values-transit.yaml 
set_ent_license_transit
init_vault_using_auto_unseal
sleep 10
