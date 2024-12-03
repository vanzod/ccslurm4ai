#!/bin/bash

IB_WRITE_BW_EXE_PATH=/opt/perftest-4.5/ib_write_bw
IB_WRITE_BW=`basename $IB_WRITE_BW_EXE_PATH`
IB_WRITE_BW_DURATION=5
IB_WRITE_BW_ARGS="-s $(( 1 * 1024 * 1024 )) -D ${IB_WRITE_BW_DURATION} -x 0 -F --report_gbits"
OUTFILE="ib_bandwidth_${HOSTNAME}_$(/bin/date '+%Y%m%dT%H%M%S').out"

VM_SKU=$(sudo /opt/cycle/jetpack/bin/jetpack config azure.metadata.compute.vmSize | tr '[:upper:]' '[:lower:]')

case $VM_SKU in
    "standard_nd96asr_v4" | "standard_nd96amsr_a100_v4")
        GPU_NUMA=( 1 1 0 0 3 3 2 2 )
        ;;
    "standard_nd96isr_h100_v5")
        GPU_NUMA=( 0 0 0 0 1 1 1 1 )
        ;;
esac

run_test_pair()
{
    SOURCE=$1
    DEST=$2

    IB_WRITE_BW_OUT1=$(numactl -N ${GPU_NUMA[$SOURCE]} \
                               -m ${GPU_NUMA[$SOURCE]} \
                               $IB_WRITE_BW_EXE_PATH \
                               $IB_WRITE_BW_ARGS \
                               --use_cuda=${SOURCE} \
                               -d mlx5_ib${SOURCE} > /dev/null &)
    sleep 2
    IB_WRITE_BW_OUT2=$(numactl -N ${GPU_NUMA[$DEST]} \
                       -m ${GPU_NUMA[$DEST]} \
                       $IB_WRITE_BW_EXE_PATH \
                       $IB_WRITE_BW_ARGS \
                       --use_cuda=${DEST} \
                       -d mlx5_ib${DEST} $HOSTNAME)

    IFS=$'\n'
    IB_WRITE_BW_OUT2_LINES=( $IB_WRITE_BW_OUT2 )
    IFS=$' \t\n'
    for ((i=0; i<${#IB_WRITE_BW_OUT2_LINES[*]}; i++))
    do
        if [[ "${IB_WRITE_BW_OUT2_LINES[$i]//1048576}" != "${IB_WRITE_BW_OUT2_LINES[$i]}" ]]; then
           LINE=( ${IB_WRITE_BW_OUT2_LINES[$i]} )
           ib_bandwidth=${LINE[3]}
           echo "mlx5_ib${SOURCE},mlx5_ib${DEST} (${GPU_NUMA[$SOURCE]},${GPU_NUMA[$DEST]}) -> $ib_bandwidth Gbps"
           break
        fi
    done
}

date | tee -a ${OUTFILE}
./get_hostnames.py | tee -a ${OUTFILE}
echo | tee -a ${OUTFILE}

for SRC in {0..6}; do
    for DEST in $(seq $(($SRC+1)) 7); do

        ps aux | grep 'nhc' | grep -q sbin
        [ $? == 0 ] && echo 'NHC is running. Stopping now!' && rm -f ${OUTFILE} && exit 1

        run_test_pair $SRC $DEST | tee -a ${OUTFILE}

    done
done
