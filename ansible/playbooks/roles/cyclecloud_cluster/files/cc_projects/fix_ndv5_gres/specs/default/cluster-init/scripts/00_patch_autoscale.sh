#!/bin/bash
set -euo pipefail

mv /opt/azurehpc/slurm/autoscale.json /opt/azurehpc/slurm/autoscale.json.orig
jq '.default_resources = [{"select": {"node.vm_size": "Standard_ND96isr_H100_v5"}, "name": "slurm_gpus", "value": 8}] + .default_resources' /opt/azurehpc/slurm/autoscale.json.orig > /opt/azurehpc/slurm/autoscale.json

