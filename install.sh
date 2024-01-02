#!/bin/bash
set -euo pipefail

RESOURCE_GROUP="<RG_NAME>"
SUBSCRIPTION="<SUB_NAME>"
REGION="<REGION>"

MYDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TEMPLATES_PATH="${MYDIR}/templates"

help()
{
    echo
    echo "Deploys and configure Azure infrastrucure for CycleCloud cluster"
    echo
    echo "USAGE: install.sh [OPTION]"
    echo "Options:"
    echo "-a    Run only ansible configuration"
    echo "-b    Run only bastion deployment"
    echo "-h    Prints this help"
    echo
}

create_bastion_scripts()
{
    TARGET_NAME=$1
    BICEP_OUTPUT_FILE=$2
    VMRESOURCEID=$3

    USER=$(jq -r '.globalVars.value.cycleserverAdmin' ${BICEP_OUTPUT_FILE})
    BASTIONNAME=$(jq -r '.globalVars.value.bastionName' ${BICEP_OUTPUT_FILE})
    KEY="${USERNAME}_id_rsa"

    for TEMPLATE_ROOT in bastion_ssh bastion_tunnel; do
        sed -e "s|<RESOURCEGROUP>|${RESOURCE_GROUP}|g" \
            -e "s|<USERNAME>|${USER}|g" \
            -e "s|<SSHKEYPATH>|${KEY}|g" \
            -e "s|<BASTIONNAME>|${BASTIONNAME}|g" \
            -e "s|<VMRESOURCEID>|${VMRESOURCEID}|g" \
            -e "s|<SUBNAME>|${SUBSCRIPTION}|g" \
            ${TEMPLATES_PATH}/${TEMPLATE_ROOT}.template > ${TEMPLATE_ROOT}_${TARGET_NAME}.sh
        chmod +x ${TEMPLATE_ROOT}_${TARGET_NAME}.sh
    done
}

# Run everything by default
RUN_BICEP=true
RUN_ANSIBLE=true

while getopts ":abh" OPT; do
    case $OPT in
        a) RUN_BICEP=false;;
        b) RUN_ANSIBLE=false;;
        h) help
           exit 0;;
        \?) help
            exit 1;;
    esac
done

##############
### CHECKS ###
##############

cmd_exists() {
    command -v "$@" &> /dev/null || { echo >&2 "$@ is required but not installed. Aborting."; exit 1; }
}

cmd_exists az
cmd_exists jq
cmd_exists perl

# Make sure submodules are also cloned
git submodule update --init --recursive

#############
### BICEP ###
#############

USERNAME=$(grep adminUsername bicep/params.bicepparam | cut -d"'" -f 2)
KEYFILE="${USERNAME}_id_rsa"

if [ ${RUN_BICEP} == true ]; then

    DEPLOYMENT_NAME=bicepdeploy-$(date +%Y%m%d%H%M%S)
    DEPLOYMENT_OUTPUT=${RESOURCE_GROUP}_${DEPLOYMENT_NAME}.json

    if [ ! -f ./${KEYFILE} ]; then
        echo "Generating new keypair for ${USERNAME}"
        ssh-keygen -m PEM -t rsa -b 4096 -f ./${KEYFILE} -N ''
        # Remove newline after public key to avoid issues when using it as parameter json files
        perl -pi -e 'chomp if eof' ./${KEYFILE}.pub
    fi

    # Make sure we are using the correct subscription
    az account set --subscription "${SUBSCRIPTION}"

    # Accept Azure Marketplace terms for CycleCloud image
    az vm image terms accept --publisher azurecyclecloud \
                             --offer azure-cyclecloud \
                             --plan cyclecloud8-gen2

    # Required to grant access to key vault secrets
    export USER_OBJECTID=$(az ad signed-in-user show --query id --output tsv)

    az group create --location ${REGION} --name ${RESOURCE_GROUP}
    az deployment group create --resource-group ${RESOURCE_GROUP} \
        	                   --template-file bicep/main.bicep \
                               --parameters bicep/params.bicepparam \
                               --name ${DEPLOYMENT_NAME}

    az deployment group show --resource-group ${RESOURCE_GROUP} \
                             --name ${DEPLOYMENT_NAME} \
                             --query properties.outputs \
                             > ${DEPLOYMENT_OUTPUT}
fi

# Use the latest available Bicep deployment output
DEPLOYMENT_OUTPUT=$(ls -t ${RESOURCE_GROUP}_bicepdeploy-*.json | head -1)

# Generate cycleserver bastion scripts
CC_VM_ID=$(jq -r '.globalVars.value.cycleserverId' ${DEPLOYMENT_OUTPUT})
create_bastion_scripts 'cycleserver' ${DEPLOYMENT_OUTPUT} ${CC_VM_ID}

###############
### ANSIBLE ###
###############

if [ ${RUN_ANSIBLE} == true ]; then
    # Install Ansible in conda environment
    [ -d ./miniconda ] || ./ansible/install/install_ansible.sh

    # Create inventory file with the appropriate variable to execute through jump host
    ANSIBLE_INVENTORY=${MYDIR}/ansible/inventory.json
    jq -s '.[0].ansible_inventory.value * {"all": .[1]}' ${DEPLOYMENT_OUTPUT} ansible/templates/ssh_jumphost_vars.json > ${ANSIBLE_INVENTORY}

    # Create global variables file
    mkdir -p ansible/group_vars/all
    jq -s '.[].globalVars.value' ${DEPLOYMENT_OUTPUT} > ansible/group_vars/all/global_vars.yml

    # Open SSH tunnel through bastion
    ./bastion_tunnel_cycleserver.sh 22 10022 &
    sleep 5

    # Kill tunnel processes on exit
    TUNNEL_PIDS=$(ps aux | grep bastion | awk '{print $2}' | head -n -1)
    trap 'kill $(echo $TUNNEL_PIDS)' EXIT

    # Run Ansible playbooks
    export ANSIBLE_CONFIG=${MYDIR}/ansible/ansible.cfg
    ansible-playbook -i ${ANSIBLE_INVENTORY} ansible/playbooks/cyclecloud.yml

    for i in {1..10}; do
        SCHEDULER_VM_ID=$(az resource list -g ${RESOURCE_GROUP} --resource-type 'Microsoft.Compute/virtualMachines' --query "[?tags.Name == 'scheduler'].id" -o tsv)

        # If scheduler VM is not yet created, wait and try again
        if [ -z "${SCHEDULER_VM_ID}" ]; then
            echo "Scheduler VM not yet allocated. Retrying bastion scripts generation in 5 seconds..."
            sleep 5
            continue
        else
            create_bastion_scripts 'scheduler' ${DEPLOYMENT_OUTPUT} ${SCHEDULER_VM_ID}
            break
        fi
    done
fi


