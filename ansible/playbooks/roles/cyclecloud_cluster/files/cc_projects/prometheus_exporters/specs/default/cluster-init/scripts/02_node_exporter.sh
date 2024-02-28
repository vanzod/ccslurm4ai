#!/bin/bash
set -euo pipefail

source $CYCLECLOUD_SPEC_PATH/files/common_functions.sh

# Install Slurm exporter only on scheduler and login VMs
if is_slurm_controller || is_login_node; then

    # Extract node exporter archive
    cd /opt
    tar xzf $CYCLECLOUD_SPEC_PATH/files/node_exporter-1.7.0.linux-amd64.tar.gz

    # Install node exporter service
    cp -v $CYCLECLOUD_SPEC_PATH/files/node_exporter.service /etc/systemd/system/

    # Create node_exporter group and user
    if ! getent group node_exporter >/dev/null; then
        groupadd -r node_exporter
    fi

    # Create node_exporter user
    if ! id -u node_exporter >/dev/null 2>&1; then
        useradd -r -g node_exporter -s /sbin/nologin node_exporter
    fi

    # Install node exporter socket
    cp -v $CYCLECLOUD_SPEC_PATH/files/node_exporter.socket /etc/systemd/system/

    # Create /etc/sysconfig directory
    mkdir -pv /etc/sysconfig

    # Copy node exporter configuration file
    cp -v $CYCLECLOUD_SPEC_PATH/files/sysconfig.node_exporter /etc/sysconfig/node_exporter

    # Create textfile_collector directory
    mkdir -pv /var/lib/node_exporter/textfile_collector
    chown node_exporter:node_exporter /var/lib/node_exporter/textfile_collector

    # Enable and start node exporter service
    systemctl daemon-reload
    systemctl enable node_exporter
    systemctl start node_exporter

fi
