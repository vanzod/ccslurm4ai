#!/bin/bash
set -euo pipefail

MONEO_VERSION='v0.3.4'

source $CYCLECLOUD_SPEC_PATH/files/common_functions.sh

# Install Moneo exporters only on compute nodes
if is_compute_node; then
    cd /opt/azurehpc/tools
    rm -rf Moneo
    git clone https://github.com/Azure/Moneo --branch ${MONEO_VERSION}

    cd /opt/azurehpc/tools/Moneo/linux_service
    ./configure_service.sh

    sed -i '/start_managed_prometheus/s/^/#/' start_moneo_services.sh
    sed -i 's/proc_check true/proc_check false/g' start_moneo_services.sh
    ./start_moneo_services.sh
fi
