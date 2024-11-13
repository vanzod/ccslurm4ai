#!/bin/bash

BANDWIDTHTEST_EXE_PATH=/usr/local/cuda/samples/1_Utilities/bandwidthTest/bandwidthTest
BANDWIDTHTEST=`basename $BANDWIDTHTEST_EXE_PATH`
OUTFILE="gpu_bandwidth_${HOSTNAME}_$(/bin/date '+%Y%m%dT%H%M%S').out"

VM_SKU=$(sudo /opt/cycle/jetpack/bin/jetpack config azure.metadata.compute.vmSize | tr '[:upper:]' '[:lower:]')

case $VM_SKU in
    "standard_nd96asr_v4" | "standard_nd96amsr_a100_v4")
        GPU_NUMA=( 1 1 0 0 3 3 2 2 )
        ;;
    "standard_nd96isr_h100_v5")
        GPU_NUMA=( 0 0 0 0 1 1 1 1 )
        ;;
esac

date | tee -a ${OUTFILE}
./get_hostnames.py | tee -a ${OUTFILE}
echo | tee -a ${OUTFILE}
nvidia-smi --query-gpu=index,pci.bus_id,gpu_serial --format=csv | tee -a ${OUTFILE}
echo | tee -a ${OUTFILE}

for test in "dtoh" "htod"; do
    for device in {0..7}; do

        ps aux | grep 'nhc' | grep -q sbin
        [ $? == 0 ] && echo 'NHC is running. Stopping now!' && rm -f ${OUTFILE} && exit 1

        numactl -N ${GPU_NUMA[$device]} \
                -m ${GPU_NUMA[$device]} \
                $BANDWIDTHTEST_EXE_PATH \
                --mode=range \
                --device=$device \
                --start=32000000 \
                --end=64000000 \
                --increment=32000000 \
                --$test | tee -a ${OUTFILE}

        CUDA_BW_RC=$?
        if [[ $CUDA_BW_RC != 0 ]]; then
            echo "$FUNCNAME: $BANDWIDTHTEST retuned error code $CUDA_BW_RC "
            exit 1
        fi
    done
done
