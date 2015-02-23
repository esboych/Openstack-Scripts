#!/bin/bash

#verbose
set -x

#Globals
BMODE=4  #bonding mode

echo "Bonding mode is $BMODE".

#reload bonding module
modprobe -r bonding
modprobe bonding mode=$BMODE miimon=100 # load bonding module

# prepare interfaces
ifconfig eth0 down
ifconfig eth1 down

ifconfig bond0 hw ether 00:11:22:33:44:54
ifconfig bond0 up

ifenslave bond0 eth0
ifenslave bond0 eth1

ifconfig eth0 up
ifconfig eth1 up

#vlan
vconfig add bond0 201
ifconfig bond0.201 192.168.55.54/24 up