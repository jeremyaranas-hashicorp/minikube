#!/usr/bin/env bash

source ../common.sh

set_ent_license
init_vault
unseal_vault
add_nodes_to_cluster