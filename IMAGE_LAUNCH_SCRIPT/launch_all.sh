#!/bin/bash

#env variables
. openrc

# assign node names authomatically
echo "Looking for hypervisors.."

#node1=$(nova hypervisor-list | awk "/ 1 / "'{print $4}' | sed s/.lst.local//g)
node1=$(nova hypervisor-list | awk "/ 1 / "'{print $4}')  # for Fue l5.1
echo "1st hypervisor:" $node1

#node2=$(nova hypervisor-list | awk "/ 2 / "'{print $4}' | sed s/.lst.local//g)
node2=$(nova hypervisor-list | awk "/ 2 / "'{print $4}')
echo "2nd hypervisor:" $node2

#verbose
#set -x

#check needed files (RSA keys and Trusty image)
files_arr=("id_rsa" "id_rsa.pub" "trusty-server-cloudimg-amd64-disk1.img")
for f in ${files_arr[*]}; do
    #echo "file: $f"
    if [ -f "$f" ]; then
      echo " File \"$f\" is found!"
    else
      echo " File \"$f\" doesn't exists, exiting!"
      exit
fi
done

echo "All  needed files found"

#create image
glance image-create --name trusty-server-cloudimg-amd64-disk1  --disk-format raw --container-format bare --file trusty-server-cloudimg-amd64-disk1.img --is-public True --progress

#image list
echo "images list:"
glance image-list

#new flawor
nova flavor-create net.1-2Gb-32Gb auto 2048 32 1 --ephemeral 0 --swap 0

#flavor list
echo "flavors list:"
nova flavor-list

#new keypar
nova keypair-add --pub-key id_rsa.pub id_rsa-key

#check keypars
echo "keypairs list:"
nova keypair-list

#iptables
nova secgroup-add-rule default icmp -1 -1 0.0.0.0/0
nova secgroup-add-rule default tcp 1 65535 0.0.0.0/0
nova secgroup-add-rule default udp 1 65535 0.0.0.0/0
nova secgroup-list-rules default

#net-list
echo "nets list:"
nova net-list



############################

#detect network parameters

#get net id ext04
neutron_net_id=$(nova net-list | awk "/net04 / "'{print $2}')
nova_net_id=($(nova net-list | awk "/novanetwork / "'{print $2}'))
echo "neutron net id: \"$neutron_net_id\""
echo "nova net id: \"$nova_net_id\""

size_neutron=${#neutron_net_id}
size_nova=${#nova_net_id}
# check what type of network we have

#if [ -n $neutron_net_id ];
if (( $size_neutron > 0 ));
then
    echo "Neutron network detected"
    fixed_net_id=$neutron_net_id
    float_net="net04_ext"
else
    echo "Nova network detected"
    fixed_net_id=$nova_net_id
    float_net="nova"
fi

echo "fixed: $fixed_net"
echo "float: $float_net"


#launching instances

echo "Launching 1st Instance.."

#launch 1st instance
nova boot --flavor net.1-2Gb-32Gb --image trusty-server-cloudimg-amd64-disk1 --key-name id_rsa-key --security-groups default --poll --nic net-id=$fixed_net_id  --availability-zone nova:$node1 Instance-nd1
#floating ip
f_ip=$(nova floating-ip-create "$float_net" | awk "/$float_net/"'{print $2}')
echo "1st Instance floating ip:" $f_ip
#assign floating ip
nova floating-ip-associate Instance-nd1 $f_ip

echo "Launching 2nd Instance.."

#launch 2nd instance
nova boot --flavor net.1-2Gb-32Gb --image trusty-server-cloudimg-amd64-disk1 --key-name id_rsa-key --security-groups default --poll --nic net-id=$fixed_net_id  --availability-zone nova:$node2 Instance-nd2
#floating ip
f_ip=$(nova floating-ip-create "$float_net" | awk "/$float_net/"'{print $2}')
echo "2nd Instance floating ip:" $f_ip
#assign floating ip
nova floating-ip-associate Instance-nd2 $f_ip