#!/usr/bin/env bash

# Prepare the host for running rpmbuilds

# install epel if required
rpm -q fedora-release || yum -y install epel-release || export RHEL=1

if [ ! -z "${RHEL}" ]; then
    EPEL_URL_PREFIX=http://dl.fedoraproject.org/pub/epel/7/x86_64/e/
    yum -y install curl
    RPM_NAME=$(curl --silent ${EPEL_URL_PREFIX} \
    | egrep -oh "epel-release-7-[0-9]*.noarch.rpm" \
    | sort -u | head -n 1)
    yum -y install ${EPEL_URL_PREFIX}${RPM_NAME}
fi

cp ${BASH_SOURCE}[0]/assets/*-sudoers /etc/sudoers.d/.

yum -y install \
    make automake gcc gcc-c++ \
    python python-devel \
    rpm-build rpmdevtools
