#!/bin/bash
set -eou pipefail

help()
{
    echo
    echo "Lists Slurm drained nodes and corresponding reason"
    echo
    echo "USAGE: drained_nodes.sh [OPTION]"
    echo "Options:"
    echo "-m    Do not colorize output"
    echo "-h    Prints this help"
    echo
}

DRAINED_NODES=$(sinfo -p hpc | awk '/drain / {print $6}')
DRAINED_UNRESP_NODES=$(sinfo -p hpc | awk '/drain\*/ {print $6}')
DOWN_NODES=$(sinfo -p hpc | awk '/down / {print $6}')
DOWN_UNRESP_NODES=$(sinfo -p hpc | awk '/down\*/ {print $6}')
MONOCHROME=false

while getopts ":mh" OPT; do
    case $OPT in
        h) help
           exit 0;;
        m) MONOCHROME=true;;
        \?) help
            exit 1;;
    esac
done    

for node in $(scontrol show hostname ${DRAINED_NODES},${DRAINED_UNRESP_NODES},${DOWN_NODES},${DOWN_UNRESP_NODES}); do
    if [ ${MONOCHROME} == true ]; then
        scontrol show node $node | awk -F'=| ' '/NodeName/ {print $2}'
    else
        scontrol show node $node | awk -F'=| ' '/NodeName/ {print "\033[1;33m" $2 "\033[0m"}'
    fi
    scontrol show node $node | awk -F'=' '/Reason/ {print $0}'
    echo
done