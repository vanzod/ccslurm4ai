#!/bin/bash
set -e
# Installs Ansible. Optionally in a conda environment.
THIS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LOG_FILE="${THIS_DIR}/ansible_install.log"

MINICONDA_URL_LINUX_X86="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh"
MINICONDA_URL_LINUX_ARM="https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-aarch64.sh"
MINICONDA_URL_MAC_X86="https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-x86_64.sh"
MINICONDA_URL_MAC_ARM="https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-arm64.sh"
MINICONDA_INSTALL_DIR="miniconda"
MINICONDA_INSTALL_SCRIPT="miniconda-installer.sh"

# Always use of virtual environment
INSTALL_IN_CONDA=${INSTALL_IN_CONDA:-true}
if [ $INSTALL_IN_CONDA = true ]; then
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

    # Reuse environment if it already exists
    if [[ ! -d "${MINICONDA_INSTALL_DIR}" ]]; then
        printf "Install Ansible in conda environment in %s from %s \n" "${MINICONDA_INSTALL_DIR}" "${miniconda_url}" | tee ${LOG_FILE}

        # Actually install environment and install in base environment
        if [[ ! -f ${MINICONDA_INSTALL_SCRIPT} ]]; then
            wget $miniconda_url -O $MINICONDA_INSTALL_SCRIPT >> ${LOG_FILE} 2>&1
        fi
        bash $MINICONDA_INSTALL_SCRIPT -b -p $MINICONDA_INSTALL_DIR >> ${LOG_FILE} 2>&1
        source "${MINICONDA_INSTALL_DIR}/bin/activate" >> ${LOG_FILE} 2>&1
    else
        printf "Install Ansible in existing conda environment in %s \n" "${MINICONDA_INSTALL_DIR}" | tee ${LOG_FILE}
        source "${MINICONDA_INSTALL_DIR}/bin/activate" >> ${LOG_FILE} 2>&1
    fi

    printf "Update conda packages\n" | tee -a ${LOG_FILE}
    conda update -y --all >> ${LOG_FILE} 2>&1

    rm -f $MINICONDA_INSTALL_SCRIPT
else
    printf "Attempting to install Ansible in base environment\n" | tee -a ${LOG_FILE}
    printf "If this fails, please run this script with the --conda flag\n\n" | tee -a ${LOG_FILE}
fi

# Install Ansible
printf "Install Ansible\n" | tee -a ${LOG_FILE}
python3 -m pip install -r ${THIS_DIR}/requirements.txt >> ${LOG_FILE} 2>&1

# Install Ansible collections
printf "Install Ansible collections\n" | tee -a ${LOG_FILE}
ansible-galaxy collection install -r ${THIS_DIR}/requirements.yml >> ${LOG_FILE} 2>&1

printf "\n"
printf "Applications installed\n"
printf "===============================================================================\n"
columns="%-16s| %.10s\n"
printf "$columns" Application Version
printf -- "-------------------------------------------------------------------------------\n"
printf "$columns" Python `python3 --version | awk '{ print $2 }'`
printf "$columns" Ansible `ansible --version | head -n 1 | awk '{ print $3 }' | sed 's/]//'`
printf "===============================================================================\n"

if [ $INSTALL_IN_CONDA = true ]; then
    yellow=$'\e[1;33m'
    default=$'\e[0m'
    printf "\n${yellow}Ansible installed in a conda environment${default}.\n"
    printf "To activate, run: source %s/bin/activate\n\n" "${MINICONDA_INSTALL_DIR}"
fi
