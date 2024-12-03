#!/bin/bash
set -euo pipefail

SUBSCRIPTION="<SUBSCRIPTION_NAME>"
RESOURCE_GROUP="<RESOURCE_GROUP_NAME>"

CATEGORIES=("Investigate" "Unhealthy" "Request")

# Additional info on error types:
# https://msazure.visualstudio.com/AzureWiki/_wiki/wikis/AzureWiki.wiki/618026/HPC-Category-list

INVESTIGATE_TYPE=("DBEOverLimit" \
                  "ECCPageRetirementTableFull" \
                  "HpcDcgmiThermalReport" \
                  "HpcGenericFailure" \
                  "HpcGpuDcgmDiagFailure" \
                  "HpcInforomCorruption" \
                  "HpcMissingGpu" \
                  "HpcRowRemapFailure" \
                  "IBPerformance" \
                  "IBPortDown" \
                  "IBPortFlapping" \
                  "MissingIB" \
                  "NvLink" \
                  "UnhealthyGPUNvidiasmi" \
                  "XID48DoubleBitECC" \
                  "XID79FallenOffBus" \
                  "XID94ContainedECCError" \
                  "XID95UncontainedECCError")

UNHEALTHY_TYPE=("AmdGpuResetFailed" \
                "CPUPerformance" \
                "DBEOverLimit" \
                "ECCPageRetirementTableFull" \
                "EROTFailure" \
                "GPUMemoryBWFailure" \
                "GpuXIDError" \
                "HpcDcgmiThermalReport" \
                "HpcGenericFailure" \
                "HpcGpuDcgmDiagFailure" \
                "HpcInforomCorruption" \
                "HpcMissingGpu" \
                "HpcRowRemapFailure" \
                "IBPerformance" \
                "IBPortDown" \
                "IBPortFlapping" \
                "ManualInvestigation" \
                "MissingIB" \
                "NvLink" \
                "UnhealthyGPUNvidiasmi" \
                "XID48DoubleBitECC" \
                "XID79FallenOffBus" \
                "XID94ContainedECCError" \
                "XID95UncontainedECCError")

REQUEST_TYPE=("Healthy"\
              "Reboot" \
              "Reset")

API_VERSION="2023-02-01-preview"

echo "Enter a VMSS instance name:"
read INSTANCE_NAME
echo
VMSS_NAME=$(echo $INSTANCE_NAME | awk -F_ '{print $1}')

echo "Enter a physical hostname:"
read PHYSICAL_HOSTNAME
echo

echo "Enter the impact description:"
read DESCRIPTION
echo

echo "Enter the impact start time (format %Y-%m-%dT%H:%M:%S.000000000Z):"
read START_TIME
echo

echo "Select an impact category:"
select OPT in "${CATEGORIES[@]}"; do
  if ! [ -z "$OPT" ]; then
    SELECTED_CATEGORY="$OPT"
    break
  fi
done
echo

case $SELECTED_CATEGORY in
  "Investigate")
    echo "Select an investigate type:"
    select OPT in "${INVESTIGATE_TYPE[@]}"; do
      if ! [ -z "$OPT" ]; then
        SELECTED_TYPE="$OPT"
        break
      fi
    done
    ;;
  "Unhealthy")
    echo "Select an unhealthy type:"
    select OPT in "${UNHEALTHY_TYPE[@]}"; do
      if ! [ -z "$OPT" ]; then
        SELECTED_TYPE="$OPT"
        break
      fi
    done
    ;;
    "Request")
    echo "Select an request:"
    select OPT in "${REQUEST_TYPE[@]}"; do
      if ! [ -z "$OPT" ]; then
        SELECTED_TYPE="$OPT"
        break
      fi
    done
    ;;
esac
echo

az account set --subscription "$SUBSCRIPTION"
SUB_ID=$(az account show --query 'id' -o tsv)

if [ $SELECTED_CATEGORY == "Request" ]; then
  IMPACT_CATEGORY="Resource.Hpc.$SELECTED_TYPE"
else
  IMPACT_CATEGORY="Resource.Hpc.$SELECTED_CATEGORY.$SELECTED_TYPE"
fi

REPORTED_TIME=$(date -u +"%Y-%m-%dT%H:%M:%S.%NZ")
VM_UUID=$(az vmss list-instances -g $RESOURCE_GROUP -n $VMSS_NAME --query "[?name=='$INSTANCE_NAME'].vmId" -o tsv)
VM_RESOURCE_ID=$(az vmss list-instances -g $RESOURCE_GROUP -n $VMSS_NAME --query "[?name=='$INSTANCE_NAME'].id" -o tsv)
[ -z $START_TIME ] && START_TIME=$REPORTED_TIME

BODY=$(cat <<EOF
{
  "properties": {
    "startDateTime": "$START_TIME",
    "reportedTimeUtc": "$REPORTED_TIME",
    "impactCategory": "$IMPACT_CATEGORY",
    "impactDescription": "$DESCRIPTION",
    "impactedResourceId": "$VM_RESOURCE_ID",
    "additionalProperties": {
      "PhysicalHostName": "${PHYSICAL_HOSTNAME}",
      "VmUniqueId": "${VM_UUID}"
    }
  }
}
EOF
)

echo $BODY | jq
echo

GUID=$(uuidgen)
URL="https://management.azure.com/subscriptions/${SUB_ID}/providers/Microsoft.Impact/workloadImpacts/${GUID}?api-version=${API_VERSION}"

az rest --method PUT --url $URL --body "$BODY"
