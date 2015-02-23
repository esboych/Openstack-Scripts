#!/bin/bash

set -x

#init data
net_name="net04"
node1="node-45"
node2="node-44"

#get net id ext04
net_id=( $(nova net-list | awk "/$net_name / "'{print $2}'))
echo "net id: " $net_id

#launch 1st instance
nova boot --flavor net.1-2Gb-32Gb --image trusty-server-cloudimg-amd64-disk1 --key-name id_rsa-key --security-groups default --poll --nic net-id=$net_id  --availability-zone nova:$node2 Instance-nd2

#floating ip
f_ip=( $(nova floating-ip-create net04_ext | awk '/net04_ext/ {print $2}'))
echo "floating ip:" $f_ip

#assign floating ip
nova floating-ip-associate Instance-nd2 $f_ip