#!/bin/bash

PMIX_VERSION='3.2.5'

function is_slurm_controller() {
    ls /lib/systemd/system/ | grep -q slurmctld
}

if is_slurm_controller; then
    mkdir -p /sched/pmix
    apt install -y libevent-dev libhwloc-dev
    tar xzf $CYCLECLOUD_SPEC_PATH/files/pmix-${PMIX_VERSION}.tar.gz
    cd pmix-${PMIX_VERSION}
    ./configure --prefix=/sched/pmix
    make
	make install
	cd ..
	rm -rf pmix-${PMIX_VERSION}
fi

# This Slurm build is not configured to find PMIx libraries at /opt/pmix/v4
ln -s /sched/pmix/lib/libpmix.so /usr/lib/libpmix.so

if is_slurm_controller; then
	systemctl restart slurmctld
else
	apt install -y libevent-pthreads-2.1-7
	systemctl restart slurmd
fi
