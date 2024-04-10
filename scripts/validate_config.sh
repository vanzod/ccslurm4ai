#!/bin/bash
# Validate the configuration file and export some varialbes to be used in install.sh and propogated to Ansible
# Var mappings:
#  "slurm_params.json2" : Ansible .globalVars.value : config.yaml
#  "HPCMachineType" : "{{ hpcSku }}" : hpc_sku
#  "MaxHPCExecuteCoreCount" : "{{ hpcMaxCoreCount }}" : hpc_max_core_count
#  "HPCMaxScalesetSize" : "{{ hpcMaxNumVMs }}" : hpc_max_num_vms
set -euo pipefail

CONFIG_FILE=${CONFIG_FILE:-config.yaml}

# hpc_sku will default to 1st entry in suppport Sku list
# - currently NDv5
EXPECTED_VARS=(
    "region" \
    "subscription_name" \
    "resource_group_name" \
    "hpc_sku" \
    "hpc_max_core_count"
)

SUPPORTED_SKUS=(
    "Standard_ND96isr_H100_v5" \
    "Standard_ND96amsr_A100_v4" \
    "Standard_ND96asr_v4"
)

# Check if config file exists and contains the expected non-null variables
if [ ! -f "${CONFIG_FILE}" ]; then
    echo "Config file not found. Please create a ${CONFIG_FILE} file with the required variables."
    exit 1
else
    for VAR in "${EXPECTED_VARS[@]}"; do
        if ! yq -e ".${VAR}" "${CONFIG_FILE}" > /dev/null; then
            echo "Error: Missing or null variable ${VAR} in ${CONFIG_FILE}"
            exit 1
        fi
    done

    # Verify HPC_SKU is supported
    HPC_SKU=$(yq -r '.hpc_sku' "${CONFIG_FILE}")
    MATCH_FOUND=${MATCH_FOUND:-}
    for SKU in "${SUPPORTED_SKUS[@]}"; do
        if [ "${HPC_SKU}" == "${SKU}" ]; then
            MATCH_FOUND=true
            export HPC_SKU
            break
        fi
    done
    if [[ -z $MATCH_FOUND ]]; then
        echo "Error: HPC SKU ${HPC_SKU} is not supported. Supported SKUs are:" "${SUPPORTED_SKUS[@]}"
        exit 1
    fi

    # Require max core count to be set
    HPC_MAX_CORE_COUNT=$(yq -r '.hpc_max_core_count' "${CONFIG_FILE}")
    export HPC_MAX_CORE_COUNT

    # Default max number of VMs per VMSS is 100 as derived from historic VMSS Uniform limits
    HPC_MAX_NUM_VMS=$(yq -r '.hpc_max_num_vms' "${CONFIG_FILE}")
    if [[ -z "${HPC_MAX_NUM_VMS}" ]]; then
        HPC_MAX_NUM_VMS=100
    fi
    export HPC_MAX_NUM_VMS

    echo "Configuration file ${CONFIG_FILE} is valid  :-)"
fi