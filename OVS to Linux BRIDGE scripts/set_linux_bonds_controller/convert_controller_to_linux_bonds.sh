#!/bin/bash

PATH="$PATH:/bin:/usr/bin:/sbin:/usr/local/bin"
netcfg_dir='/etc/sysconfig/network-scripts'
backup_netcfg_dir='/root/ifcfg/backup'
mgmt_bond='bond0'
#storage_bond='bond1'
mgmt_vlan='566'
ext_vlan='568'
storage_vlan='567'
bond0_if0='eth0'
bond0_if1='eth1'
#bond1_if0='eth1'
#bond1_if1='eth3'
#Linux naming convention do not allow to include Linux bond names to any OVS names
#Do not include parts like 'bond0', 'bond1' etc to OVS names at all!
mgmt_bridge='br-bnd0'
#storage_bridge='br-bnd1'
cidr_br_ex='95.173.212.12/24'
cidr_br_mgmt='172.18.4.4/22'
cidr_br_storage='172.18.8.3/22'
#backup existing ifconfig scripts
mkdir $backup_netcfg_dir
cp -b $netcfg_dir/ifcfg* $backup_netcfg_dir/

#down the existing ports
ip l set down dev $bond0_if0
ip l set down dev $bond0_if1
#ip l set down dev $bond1_if0
#ip l set down dev $bond1_if1
ip l set down dev $mgmt_bond
#ip l set down dev $storage_bond

ifdown $bond0_if0
ifdown $bond0_if1
#ifdown $bond1_if0
#ifdown $bond1_if1
ifdown $mgmt_bond
#ifdown $storage_bond

#copy prepared ifcfg scripts to the target dir
\cp /root/ifcfg/ifcfg* $netcfg_dir/

#del existing extra OVS bridge
ip addr del "$cidr_br_ex" dev br-ex
ip addr del "$cidr_br_mgmt" dev br-mgmt
ip addr del "$cidr_br_storage" dev br-storage

ovs-vsctl del-br br-ovs-bond0
#ovs-vsctl del-port br-mgmt br-mgmt--br-ovs-bond0
#ovs-vsctl del-port br-ex br-ex--br-ovs-bond0

#ovs-vsctl del-br br-ovs-bond1
#ovs-vsctl del-port br-storage br-storage--br-ovs-bond1

rmmod bonding
modprobe bonding max_bonds=2 xmit_hash_policy=2 mode=4

#start up new NICs and bonds
ifup $bond0_if0
ifup $bond0_if1
#ifup $bond1_if0
#ifup $bond1_if1
ifup $mgmt_bond
#ifup $storage_bond
ifup "$mgmt_bond.$mgmt_vlan"
ifup "$mgmt_bond.$ext_vlan"
ifup "$mgmt_bond.$storage_vlan"

#ip addr add 95.173.212.13/24 dev "$mgmt_bond.$mgmt_vlan"
#ip addr add 172.18.4.5/22 dev "$mgmt_bond.$ext_vlan"
#ip addr add 172.18.8.4/22 dev "$storage_bond.$storage_vlan"


#add new bridges
ovs-vsctl add-br $mgmt_bridge
#ovs-vsctl add-br $storage_bridge

#ovs-vsctl add-port br-bnd1 br-bnd1 -- set interface br-bnd1 type=internal
#ovs-vsctl add-port br-bnd0 br-bnd0 -- set interface br-bnd0 type=internal

ovs-vsctl add-port br-ex br-ex--"$mgmt_bridge" -- set interface br-ex--"$mgmt_bridge" type=patch options:peer="$mgmt_bridge"--br-ex
ovs-vsctl add-port "$mgmt_bridge" "$mgmt_bridge"--br-ex tag=$ext_vlan -- set interface "$mgmt_bridge"--br-ex type=patch options:peer=br-ex--"$mgmt_bridge"
ovs-vsctl add-port br-mgmt br-mgmt--"$mgmt_bridge" -- set interface br-mgmt--"$mgmt_bridge" type=patch options:peer="$mgmt_bridge"--br-mgmt
ovs-vsctl add-port "$mgmt_bridge" "$mgmt_bridge"--br-mgmt tag=$mgmt_vlan -- set interface "$mgmt_bridge"--br-mgmt type=patch options:peer=br-mgmt--"$mgmt_bridge"

ovs-vsctl add-port br-storage br-str--"$mgmt_bridge" -- set interface br-str--"$mgmt_bridge" type=patch options:peer="$mgmt_bridge"--br-str
ovs-vsctl add-port "$mgmt_bridge" "$mgmt_bridge"--br-str tag=$storage_vlan -- set interface "$mgmt_bridge"--br-str type=patch options:peer=br-str--"$mgmt_bridge"

