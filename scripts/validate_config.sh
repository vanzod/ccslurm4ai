#!/bin/bash
set -euo pipefail

CONFIG_FILE=$1

EXPECTED_VARS=("region" \
               "subscription_name" \
               "resource_group_name")

# Check if config file exists and contains the expected non-null variables
if [ ! -f "${CONFIG_FILE}" ]; then
    echo "Config file not found. Please create a ${CONFIG_FILE} file with the required variables."
    exit 1
else 
    for VAR in "${EXPECTED_VARS[@]}"; do
        if ! yq -e ".${VAR}" ${CONFIG_FILE} > /dev/null; then
            echo "Error: Missing or null variable ${VAR} in ${CONFIG_FILE}"
            exit 1
        fi
    done

    echo "Configuration file ${CONFIG_FILE} is valid  :-)"
fi