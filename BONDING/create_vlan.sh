#!/bin/bash

#Script for creating vlan200 locally and linking bridging interface bond0 to it
ip link add name vlan200 link bond0 type vlan id 200
ip address add 192.168.55.56/24 dev vlan200
ip link set vlan200 up