#!/bin/bash
# Installs Ansible in base conda environment installed in miniconda directory
set -e

THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
MINICONDA_URL_LINUX_X86="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"
MINICONDA_URL_LINUX_ARM="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-aarch64.sh"
MINICONDA_URL_MAC_X86="https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-x86_64.sh"
MINICONDA_URL_MAC_ARM="https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-arm64.sh"
MINICONDA_INSTALL_DIR="miniconda"
MINICONDA_INSTALL_SCRIPT="miniconda-installer.sh"

# If currently in active conda environment, deactivate to avoid conflicts.
# Cannot use conda deactivate in a script, so use source deactivate despite being deprecated.
if [ -n "${CONDA_PREFIX}" ]; then
    source deactivate
    echo "${CONDA_PREFIX} environment deactivated"
fi

# Identify OS and architecture
os_type=$(uname | awk '{print tolower($0)}')
os_arch=$(arch)
if [[ "$os_type" == "darwin" ]]; then
    if [[ "$os_arch" == "arm64" ]]; then
        miniconda_url=$MINICONDA_URL_MAC_ARM
    else
        miniconda_url=$MINICONDA_URL_MAC_X86
    fi
elif [[ "$os_type" == "linux" ]]; then
    if [[ "$os_arch" == "aarch64" ]]; then
        miniconda_url=$MINICONDA_URL_LINUX_ARM
    else
        miniconda_url=$MINICONDA_URL_LINUX_X86
    fi
else
    printf "Unsupported OS"
    exit 1
fi

# Install conda, reuse install script if it already exists, and activate base environment
printf "Installing Ansible in base conda environment in '%s' directory from %s \n" "${MINICONDA_INSTALL_DIR}" "${miniconda_url}"
wget $miniconda_url -O $MINICONDA_INSTALL_SCRIPT
bash $MINICONDA_INSTALL_SCRIPT -b -p $MINICONDA_INSTALL_DIR
source "${MINICONDA_INSTALL_DIR}/bin/activate"
rm -f $MINICONDA_INSTALL_SCRIPT

# Install Ansible
printf "Installing Ansible\n"
python3 -m pip install -r "${THIS_DIR}/requirements.txt"

# Install Ansible collections
printf "Installing Ansible collections\n"
ansible-galaxy collection install -r "${THIS_DIR}/requirements.yml"