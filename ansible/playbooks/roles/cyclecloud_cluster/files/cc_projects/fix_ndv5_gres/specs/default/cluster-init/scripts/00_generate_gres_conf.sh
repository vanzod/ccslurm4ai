#!/bin/bash
set -euo pipefail

NODES=$(awk -F'[ =]' '/PartitionName=hpc/{print $4}' /sched/slurmcluster/azure.conf)
echo "Nodename=${NODES} Name=gpu Count=8 File=/dev/nvidia[0-7]" > /sched/slurmcluster/gres.conf
