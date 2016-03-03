#!/bin/bash

#This script should be run from the Master node in order to install and launch Shaker agents
set -x

#Define global variables
# Define SSH template:
SSH_OPTS='-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
#SSH_CMD="ssh root@"
SSH_CMD="ssh root@"
SCP_CMD="scp root@"
USER_NAME=root
export CONTROLLER_ADMIN_IP=10.20.0.7
export MASTER_COMPUTE_ADMIN_IP=10.20.0.5
export SLAVE_COMPUTE_ADMIN_IP=10.20.0.6
export SERVER_PORT=18000

export CONTROLLER_PUBLIC_IP=$($SSH_CMD${CONTROLLER_ADMIN_IP} "ifconfig | grep br-ex -A 1 | grep inet | awk ' {print \$2}' | sed 's/addr://g'")
echo "Controller Public IP: $CONTROLLER_PUBLIC_IP"

export SLAVE_COMPUTE_PRIVATE_IP=$($SSH_CMD${SLAVE_COMPUTE_ADMIN_IP} "ifconfig | grep br-mgmt -A 1 | grep inet | awk ' {print \$2}' | sed 's/addr://g'")
echo "Slave Compute Private IP: $SLAVE_COMPUTE_PRIVATE_IP"


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

# Update traffic.py file to have stdev and median values in the report
# get new traffic.py file
wget -nc https://raw.githubusercontent.com/esboych/Openstack-Scripts/master/SHAKER_LAUNCH_AUTOMATION/traffic.py

#copy it to Controller node
scp traffic.py root@10.20.0.7:/root/traffic.py




###################################### Run shaker on Computes ################################################

#Create script to run on Compute #1
echo "Run agent on Compute #1"

# Create script for run on compute
REMOTE_SCRIPT=`${SSH_CMD}$MASTER_COMPUTE_ADMIN_IP "mktemp"`

${SSH_CMD}$MASTER_COMPUTE_ADMIN_IP "cat > ${REMOTE_SCRIPT}" <<EOF
#!/bin/bash -xe

#Fill in sources.list
printf 'deb http://ua.archive.ubuntu.com/ubuntu/ trusty universe' > /etc/apt/sources.list
apt-get update

#kill shaker agent if already run
killall shaker || true

#install iperf
apt-get install iperf

#install Shaker
apt-get -y install python-dev libzmq-dev python-pip && pip install pbr pyshaker

iptables -I INPUT -s 10.20.0.0/16 -j ACCEPT
iptables -I INPUT -s 10.0.0.0/16 -j ACCEPT
iptables -I INPUT -s 172.16.0.0/16 -j ACCEPT
iptables -I INPUT -s 192.168.0.0/16 -j ACCEPT

#run shaker agent#1
shaker-agent --agent-id a-001 --server-endpoint $CONTROLLER_PUBLIC_IP:$SERVER_PORT --debug
EOF

#Run script on remote node and get exit code
${SSH_CMD}$MASTER_COMPUTE_ADMIN_IP -f  "bash -xe ${REMOTE_SCRIPT}"

###################################################

#Create script to run on Compute #2
echo "Run agent on Compute #2"

# Create script for run on compute
REMOTE_SCRIPT=`${SSH_CMD}$SLAVE_COMPUTE_ADMIN_IP "mktemp"`

${SSH_CMD}$SLAVE_COMPUTE_ADMIN_IP "cat > ${REMOTE_SCRIPT}" <<EOF
#!/bin/bash -xe

#Fill in sources.list
printf 'deb http://ua.archive.ubuntu.com/ubuntu/ trusty universe' > /etc/apt/sources.list
apt-get update

#kill shaker agent if already run
killall shaker || true

#install iperf
apt-get install iperf

#install Shaker
apt-get -y install python-dev libzmq-dev python-pip && pip install pbr pyshaker

iptables -I INPUT -s 10.20.0.0/16 -j ACCEPT
iptables -I INPUT -s 10.0.0.0/16 -j ACCEPT
iptables -I INPUT -s 172.16.0.0/16 -j ACCEPT
iptables -I INPUT -s 192.168.0.0/16 -j ACCEPT

#run iperf
#iperf -s

#run shaker agent#2
shaker-agent --agent-id a-002 --server-endpoint $CONTROLLER_PUBLIC_IP:$SERVER_PORT --debug
EOF

#Run script on remote node and get exit code
${SSH_CMD}$SLAVE_COMPUTE_ADMIN_IP -f "bash -xe ${REMOTE_SCRIPT}"




##################################### Run Shaker on Controller ################################################

echo "Run Shaker on Controller"

# Create script for run on controller
REMOTE_SCRIPT=`${SSH_CMD}$CONTROLLER_ADMIN_IP "mktemp"`

echo "!!! Running Controller"
${SSH_CMD}$CONTROLLER_ADMIN_IP "cat > ${REMOTE_SCRIPT}" <<EOF
#!/bin/bash -xe

#kill shaker agent if already run
killall shaker || true

# Prepare environment
source /root/openrc

apt-get -y install python-dev libzmq-dev python-pip && pip install pbr pyshaker

#copy traffic.py to destination
cp traffic.py /usr/local/lib/python2.7/dist-packages/shaker/engine/aggregators

#edit v2.py file in order to use keystone v2 api
sed -i "s/'\/tokens/'\/v2.0\/tokens/" /usr/lib/python2.7/dist-packages/keystoneclient/auth/identity/v2.py

iptables -I INPUT -s 10.20.0.0/16 -j ACCEPT
iptables -I INPUT -s 10.0.0.0/16 -j ACCEPT
iptables -I INPUT -s 172.16.0.0/16 -j ACCEPT
iptables -I INPUT -s 192.168.0.0/16 -j ACCEPT

#Creating a scenario file
printf 'description:\n   This scenario run bare agents \n\ndeployment:\n  agents:\n  -\n   id: a-001\n   ip: 10.20.1.2\n   mode: master\n   slave_id: a-002\n\n  -\n   id: a-002\n   ip: $SLAVE_COMPUTE_PRIVATE_IP\n   mode: slave\n   master_id: a-001\n\nexecution:\n  tests:\n  -\n    title: Iperf TCP\n    class: iperf_graph\n    threads: 22\n    time: 180\n' \
> /usr/local/lib/python2.7/dist-packages/shaker/scenarios/networking/static_agents_pair_baremetal.yaml

shaker --server-endpoint $CONTROLLER_PUBLIC_IP:$SERVER_PORT --scenario networking/static_agents_pair_baremetal --report perf_baremetal_nodes_VLAN.html --debug

EOF

#Run script on remote node and get exit code
${SSH_CMD}$CONTROLLER_ADMIN_IP "bash -xe ${REMOTE_SCRIPT}"
