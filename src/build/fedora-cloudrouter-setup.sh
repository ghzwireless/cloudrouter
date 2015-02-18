#!/usr/bin/env bash

TMPDIR=${TMPDIR-/tmp}
BUILD_DIR=$(mktemp --directory --tmpdir=${TMPDIR} cloudrouter.setup.XXXXXXXXXX)
cd ${BUILD_DIR}

# get some detals going
sudo yum install -y wget deltarpm

# setup the cloudrouter repository
sudo yum install --assumeyes \
    https://cloudrouter.org/repo/beta/x86_64/cloudrouter-release-1-1.noarch.rpm
sudo rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CLOUDROUTER

# remove any packages here
sudo yum -y remove \
    docker

# ensure we are up-to-date
sudo yum update -y

# Cleanup
cd ~/ && rm -rf ${BUILD_DIR}
sudo yum clean all
