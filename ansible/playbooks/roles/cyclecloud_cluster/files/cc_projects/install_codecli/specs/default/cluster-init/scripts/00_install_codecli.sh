#!/bin/bash
set -euo pipefail

cd /tmp
wget https://vscode.download.prss.microsoft.com/dbazure/download/stable/1e790d77f81672c49be070e04474901747115651/code_1.87.1-1709685762_amd64.deb
apt install -y /tmp/code_1.87.1-1709685762_amd64.deb
rm -f code_1.87.1-1709685762_amd64.deb