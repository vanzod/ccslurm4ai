#!/bin/bash

if ! [ -f /root/reboot.sh ]; then
    for file in reboot setup_nvme_heal; do
        cp $CYCLECLOUD_SPEC_PATH/files/${file}.sh /root
        chmod +x /root/${file}.sh
    done
fi

if ! [ -f /etc/crontab.orig ]; then
    cp /etc/crontab /etc/crontab.orig
    echo "@reboot root /root/reboot.sh" | tee -a /etc/crontab
fi
