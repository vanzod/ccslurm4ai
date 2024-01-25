#!/bin/bash
set -euo pipefail

echo "AccountingStorageHost=$(hostname)" >> /etc/slurm/accounting.conf
