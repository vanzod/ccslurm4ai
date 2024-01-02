#!/bin/bash
set -euo pipefail

NODES=$(awk -F'[ =]' '/PartitionName=hpc/{print $4}' /sched/slurmcluster/azure.conf)
awk -v nodes="$NODES" '{if ($1=="Nodename="nodes) print $0, "Gres=gpu:8"; else print $0}' /sched/slurmcluster/azure.conf > /tmp/azure.conf.tmp
chmod 644 /tmp/azure.conf.tmp
mv /tmp/azure.conf.tmp /sched/slurmcluster/azure.conf
