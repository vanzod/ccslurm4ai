#!/bin/bash
set -euo pipefail

CONFIG_FILE=$1

# hpc_sku will default to 1st entry in suppport Sku list
# - currently NDv5
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

    # Add HPC sku if defined in the config file
    HPC_SKU=$(yq -r '.hpc_sku' "${CONFIG_FILE}")
    if [ -z "${HPC_SKU}" ]; then
        # Default if first SKU is array, NDv5
        HPC_SKU="${SUPPORTED_SKUS[0]}"
    else
        for SKU in "${SUPPORTED_SKUS[@]}"; do
            if [ "${HPC_SKU}" == "${SKU}" ]; then
                MATCH_FOUND=true
                break
            fi
        done
        if [[ -z "${MATCH_FOUND}" ]]; then
            echo "Error: HPC SKU ${HPC_SKU} is not supported. Supported SKUs are:" "${SUPPORTED_SKUS[@]}"
            exit 1
        fi
    fi

    echo "Configuration file ${CONFIG_FILE} is valid  :-)"
fi