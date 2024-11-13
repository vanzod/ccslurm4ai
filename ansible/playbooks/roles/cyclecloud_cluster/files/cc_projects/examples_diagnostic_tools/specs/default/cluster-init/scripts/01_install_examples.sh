#!/bin/bash
set -euo pipefail

ROOT_DIR=/shared/home/cycleadmin

if [ ! -d $ROOT_DIR/examples ]; then
    cp -r $CYCLECLOUD_SPEC_PATH/files/examples $ROOT_DIR/examples
fi
