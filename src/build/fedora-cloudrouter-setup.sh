#!/usr/bin/env bash

# setup the cloudrouter repository
sudo yum install --assumeyes \
    https://cloudrouter.org/repo/beta/x86_64/cloudrouter-release-1-1.noarch.rpm
sudo rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CLOUDROUTER

# remove any packages here
sudo yum -y remove \
    docker
