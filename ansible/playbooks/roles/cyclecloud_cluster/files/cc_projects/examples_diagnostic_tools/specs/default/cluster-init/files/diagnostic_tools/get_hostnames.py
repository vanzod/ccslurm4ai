#!/usr/bin/python3

import os
import struct
import socket
from subprocess import Popen, PIPE

hostname = socket.gethostname()

def get_oshostname():
    return socket.gethostname()

def get_physicalhostname():
    file_path='/var/lib/hyperv/.kvp_pool_3'
    fileSize = os.path.getsize(file_path)
    num_kv = int(fileSize /(512+2048))
    file = open(file_path,'rb')
    for i in range(0, num_kv):
        key, value = struct.unpack("512s2048s",file.read(2560))
        key = key.split(b'\x00')
        value = value.split(b'\x00')
        if "PhysicalHostNameFullyQualified" in str(key[0]):
           return str(value[0])[2:][:-1]

def get_vmss_hostname():
    cmd='curl -s -H Metadata:true --noproxy "*" "http://169.254.169.254/metadata/instance?api-version=2021-02-01" | jq ".compute.name" -r'
    cmdobj = Popen(cmd, stdout=PIPE, stderr=PIPE, shell=True)
    stdout = cmdobj.communicate()[0]
    hostname = stdout.decode().strip()
    return hostname

def get_nodeid():
    cmd='sudo dmidecode -s system-uuid'
    cmdobj = Popen(cmd, stdout=PIPE, stderr=PIPE, shell=True)
    stdout = cmdobj.communicate()[0]
    hostname = stdout.decode().strip()
    return hostname

def main():
    print("{} {} {} {}".format(get_oshostname(), get_vmss_hostname(), get_physicalhostname(), get_nodeid()))

if __name__ == "__main__":
       main()
