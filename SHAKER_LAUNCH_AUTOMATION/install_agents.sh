#!/bin/bash

#This script should be run from the Master node in order to install and launch Shaker agents
set -x

#Define global variables
# Define SSH template:
SSH_OPTS='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
SSH_CMD="ssh root@"
SCP_CMD="scp root@"
USER_NAME=root


#Define Controller IP adresses
CONTROLLER_IP_ARRAY=($(fuel node | awk '/controller/ {print $10}')) #Array of controller IPs in HA case
#Print out Controllers IPs
echo "Controller IPs:"
for i in ${CONTROLLER_IP_ARRAY[@]};
do
    echo $i
done
#Define compute IPs
COMPUTE_IP_ARRAY=($(fuel node | awk '/compute/ {print $10}')) #Array of controller IPs in HA case
#Print out Controllers IPs
echo "Compute IPs:"
for i in ${COMPUTE_IP_ARRAY[@]};
do
    echo $i
    done

#Get timestamp
TIME="MSK-$(date +%Y-%m-%d-%H:%M:%S)"
echo -n "Begin Shaker test(s) at "
date




##################################### Run Shaker on Controller ################################################

#check SSH
#NODE_IP=${CONTROLLER_IP_ARRAY[0]}
#NODE_IP=172.16.53.68
NODE_IP=10.20.0.3
echo "Run Shaker on Controller"
echo "Controller IP: $NODE_IP"

# Copy keys to Controller node
${SCP_CMD}$NODE_IP:/root/.ssh/id_rsa id_rsa.${USER_NAME}

# Create remote dir.
REPORTS_DIR=`${SSH_CMD}$NODE_IP "mktemp -d"`
echo "Created reports dir name: " $REPORTS_DIR


# Create script for run on controller
REMOTE_SCRIPT=`${SSH_CMD}$NODE_IP "mktemp"`

echo "!!! -2- Running SSH_CMD"
${SSH_CMD}$NODE_IP "cat > ${REMOTE_SCRIPT}" <<\EOF
#!/bin/bash -xe

SHAKER_PATH=${SHAKER_PATH}
TEST_SUBJECT=${TEST_SUBJECT:-networking}
REPORTS_DIR=`mktemp -d`
#SERVER_ENDPOINT=172.16.53.68
# get br-ex IP address to use with --server-endpoint Shaker's option
SERVER_ENDPOINT=`ifconfig | grep "br-ex" -A 3 | grep "inet addr" | awk '{print $2}' | sed 's/addr://g'`
SERVER_PORT=18000


# Prepare environment
source /root/openrc

apt-get -y install python-dev libzmq-dev python-pip && pip install pbr pyshaker

iptables -I INPUT -s 10.20.0.0/16 -j ACCEPT
iptables -I INPUT -s 10.0.0.0/16 -j ACCEPT
iptables -I INPUT -s 172.16.0.0/16 -j ACCEPT
iptables -I INPUT -s 192.168.0.0/16 -j ACCEPT

shaker-image-builder --debug

#Creating a scenario file
printf 'description:\n   This scenario launches pairs of VMs \ndeployment:\n  template: l2.hot\n  accommodation: [pair, single_room]\nexecution:\n  progression: quadratic\n  tests:\n  -\n    title: Iperf TCP\n    class: iperf_graph\n    threads: 22\n    time: 180\n' \
> /usr/local/lib/python2.7/dist-packages/shaker/scenarios/networking/iperf_instances_diff_node.yaml

echo "SERVER_ENDPOINT: $SERVER_ENDPOINT"
shaker --server-endpoint $SERVER_ENDPOINT:18000 --scenario networking/iperf_instances_diff_node --report perf_instances_VLAN.html --debug

EOF

#Run script on remote node and get exit code
${SSH_CMD}$NODE_IP "bash -xe ${REMOTE_SCRIPT}"