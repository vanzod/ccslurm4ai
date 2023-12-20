#!/bin/bash

cp -v $CYCLECLOUD_SPEC_PATH/files/cli.py /opt/azurehpc/slurm/venv/lib/python3.*/site-packages/slurmcc/cli.py
cp -v $CYCLECLOUD_SPEC_PATH/files/util.py /opt/azurehpc/slurm/venv/lib/python3.*/site-packages/slurmcc/util.py
