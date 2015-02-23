#!/bin/bash

PATH="$PATH:/bin:/usr/bin:/sbin:/usr/local/bin"

nohup puppet apply -d /etc/puppet/manifests/setup_linux_bond_network.pp 2>&1 | tee /root/puppet_network.log