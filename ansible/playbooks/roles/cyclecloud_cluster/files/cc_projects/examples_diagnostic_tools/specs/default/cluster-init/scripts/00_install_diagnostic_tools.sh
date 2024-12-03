#!/bin/bash
set -euo pipefail

ROOT_DIR=/shared/home/cycleadmin

if [ ! -d $ROOT_DIR/diagnostic_tools ]; then
    cp -r $CYCLECLOUD_SPEC_PATH/files/diagnostic_tools $ROOT_DIR/diagnostic_tools
    chmod 744 $ROOT_DIR/diagnostic_tools/*.sh
    chmod 744 $ROOT_DIR/diagnostic_tools/*.py
    chown -R cycleadmin:cycleadmin $ROOT_DIR/diagnostic_tools
fi
