#!/bin/bash

OSRELEASE=$(uname -r | awk -F . '{ print $(NF-1) }')
ARCH=$(uname -i)
CORERELEASE="1"
COREVERSION="4.8"

if type dnf > /dev/null 2>&1; then
    dnf install bash bridge-utils ebtables iproute libev python procps-ng net-tools tcl tk tkimg kernel-modules-extra quagga bird traceroute python-pip -y
else
    yum install bash bridge-utils ebtables iproute libev python procps-ng net-tools tcl tk tkimg kernel-modules-extra quagga bird traceroute python-pip -y
fi
pip install trparse

curl -o core-daemon-${COREVERSION}-${CORERELEASE}.${OSRELEASE}.${ARCH}.rpm http://downloads.pf.itd.nrl.navy.mil/core/packages/${COREVERSION}/core-daemon-${COREVERSION}-${CORERELEASE}.${OSRELEASE}.${ARCH}.rpm
curl -o core-gui-${COREVERSION}-${CORERELEASE}.${OSRELEASE}.noarch.rpm http://downloads.pf.itd.nrl.navy.mil/core/packages/${COREVERSION}/core-gui-${COREVERSION}-${CORERELEASE}.${OSRELEASE}.noarch.rpm

if type dnf > /dev/null 2>&1; then
    dnf install --nogpgcheck -y core-daemon-${COREVERSION}-${CORERELEASE}.${OSRELEASE}.${ARCH}.rpm core-gui-${COREVERSION}-${CORERELEASE}.${OSRELEASE}.noarch.rpm
else
    yum localinstall --nogpgcheck -y core-daemon-${COREVERSION}-${CORERELEASE}.${OSRELEASE}.${ARCH}.rpm core-gui-${COREVERSION}-${CORERELEASE}.${OSRELEASE}.noarch.rpm
fi

if type systemctl > /dev/null 2>&1; then
    systemctl disable firewalld
    systemctl stop firewalld
    systemctl disable iptables.service
    systemctl stop iptables.service
    systemctl disable ip6tables.service
    systemctl stop ip6tables.service
    systemctl daemon-reload
    systemctl start core-daemon.service
else
    chkconfig iptables off
    service iptables stop
    chkconfig ip6tables off
    service ip6tables stop
    chkconfig core-daemon on
    service core-daemon start
fi
