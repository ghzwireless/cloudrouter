#!/bin/bash

yum install bash bridge-utils ebtables iproute libev python procps-ng net-tools tcl tk tkimg kernel-modules-extra quagga bird traceroute python-pip -y
pip install trparse

curl -o core-daemon-4.7-1.fc20.x86_64.rpm http://downloads.pf.itd.nrl.navy.mil/core/packages/4.7/core-daemon-4.7-1.fc20.x86_64.rpm
curl -o core-gui-4.7-1.fc20.noarch.rpm http://downloads.pf.itd.nrl.navy.mil/core/packages/4.7/core-gui-4.7-1.fc20.noarch.rpm
yum localinstall --nogpgcheck -y core-daemon-4.7-1.fc20.x86_64.rpm core-gui-4.7-1.fc20.noarch.rpm

systemctl disable firewalld
systemctl stop firewalld
systemctl disable iptables.service
systemctl stop iptables.service
systemctl disable ip6tables.service
systemctl stop ip6tables.service

systemctl daemon-reload
systemctl start core-daemon.service
