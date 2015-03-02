#!/usr/bin/env bash

EPEL_URL_PREFIX=http://dl.fedoraproject.org/pub/epel/7/x86_64/e/

# install any requirements
yum -y install curl

RPM_NAME=$(curl --silent ${EPEL_URL_PREFIX} \
    | egrep -oh "epel-release-7-[0-9]*.noarch.rpm" \
    | sort -u | head -n 1)

yum -y install ${EPEL_URL_PREFIX}${RPM_NAME}
