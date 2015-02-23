!/bin/bash

# This script is supposed to run in Neutron network with net04 and net04_ext networks present

#init data
net_name="net04"
node1="node-52"
node2="node-54"

#env variables
. openrc

#verbose
#set -x

#check needed files

    
files_arr=("id_rsa" "id_rsa.pub" "trusty-server-cloudimg-amd64-disk1.img")
    
for f in ${files_arr[*]}; do
    #echo "file: $f"
    if [ -f "$f" ]; then
      echo " File $f is found!"
    else
      echo " File \"$f\" doesn't exists, exiting!"
      exit
fi
done

echo "All  needed files found"

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

############################

#launching instances

#get net id ext04
net_id=( $(nova net-list | awk "/$net_name / "'{print $2}'))
echo "net id: " $net_id

#launch 1st instance
nova boot --flavor net.1-2Gb-32Gb --image trusty-server-cloudimg-amd64-disk1 --key-name id_rsa-key --security-groups default --poll --nic net-id=$net_id  --availability-zone nova:$node2 Instance-nd1
#floating ip
f_ip=( $(nova floating-ip-create net04_ext | awk '/net04_ext/ {print $2}'))
echo "floating ip:" $f_ip
#assign floating ip
nova floating-ip-associate Instance-nd1 $f_ip


#launch 2nd instance
nova boot --flavor net.1-2Gb-32Gb --image trusty-server-cloudimg-amd64-disk1 --key-name id_rsa-key --security-groups default --poll --nic net-id=$net_id  --availability-zone nova:$node2 Instance-nd2
#floating ip
f_ip=( $(nova floating-ip-create net04_ext | awk '/net04_ext/ {print $2}'))
echo "floating ip:" $f_ip
#assign floating ip
nova floating-ip-associate Instance-nd2 $f_ip