#!/usr/bin/env bash

VBOX_REPO=http://download.virtualbox.org/virtualbox/rpm/rhel/virtualbox.repo

curl -o /etc/yum.repos.d/$(basename ${VBOX_REPO}) ${VBOX_REPO}
yum -y install \
    VirtualBox-* \
    libstdc++ libstdc++-static
