#!/bin/bash

. openrc

#verbose
set -x

#create image
glance image-create --name trusty-server-cloudimg-amd64-disk1  --disk-format raw --container-format bare --file trusty-server-cloudimg-amd64-disk1.img --is-public True --progress

#image list
glance image-list

#new flawor
nova flavor-create net.1-2Gb-32Gb auto 2048 32 1 --ephemeral 0 --swap 0

#flavor list
nova flavor-list

#new keypar
nova keypair-add --pub-key id_rsa.pub id_rsa-key

#check keypars
nova keypair-list

#iptables
nova secgroup-add-rule default icmp -1 -1 0.0.0.0/0
nova secgroup-add-rule default tcp 1 65535 0.0.0.0/0
nova secgroup-add-rule default udp 1 65535 0.0.0.0/0
nova secgroup-list-rules default

#net-list
nova net-list