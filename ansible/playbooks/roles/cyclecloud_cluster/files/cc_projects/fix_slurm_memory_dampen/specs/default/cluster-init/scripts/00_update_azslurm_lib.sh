#!/usr/bin/env bash
# This script is used to update the azslurm library to fix the memory dampening issue.
# This workaround will should no longer be required for azslurm versions >= 3.0.7
set -e

for p in util.py cli.py partition.py ; do
    wget -O /opt/azurehpc/slurm/venv/lib/python3.*/site-packages/slurmcc/${p} https://raw.githubusercontent.com/Azure/cyclecloud-slurm/d926bb53ed4dd37df5e3f3729919b3fb2475aa50/slurm/src/slurmcc/${p}
done
/root/bin/azslurm scale