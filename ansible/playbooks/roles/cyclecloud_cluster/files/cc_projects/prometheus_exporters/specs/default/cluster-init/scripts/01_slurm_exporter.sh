#!/bin/bash
set -euo pipefail

source $CYCLECLOUD_SPEC_PATH/scripts/common_functions.sh

# Install Slurm exporter only on scheduler VM
if is_slurm_controller; then

    apt install -y golang-go

    cd /opt
    rm -rf prometheus-slurm-exporter
    git clone -b development https://github.com/vpenso/prometheus-slurm-exporter.git
    cd prometheus-slurm-exporter
    make

    cp $CYCLECLOUD_SPEC_PATH/files/prometheus-slurm-exporter.service /etc/systemd/system
    systemctl daemon-reload
    systemctl enable prometheus-slurm-exporter
    systemctl start prometheus-slurm-exporter

fi

