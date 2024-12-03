#!/bin/bash
set -euo pipefail

sed -i '/CgroupAutomount/s/^/#/' /etc/slurm/cgroup.conf