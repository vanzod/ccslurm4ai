#!/bin/bash

function is_slurm_controller() {
    ls /lib/systemd/system/ | grep -q slurmctld
}

if is_slurm_controller; then
    mkdir -p /sched/pmix/v4
    apt install -y libevent-dev libhwloc-dev
    tar xzf $CYCLECLOUD_SPEC_PATH/files/pmix-4.2.8.tar.gz
    cd pmix-4.2.8
    ./configure --prefix=/sched/pmix/v4
    make
	make install
	cd ..
	rm -rf pmix-4.2.8
fi

# This Slurm build is not configured to find PMIx libraries at /opt/pmix/v4
ln -s /sched/pmix/v4/lib/libpmix.so /usr/lib/libpmix.so

if is_slurm_controller; then
	systemctl restart slurmctld
else
	apt install -y libevent-pthreads-2.1-7
	systemctl restart slurmd
fi
