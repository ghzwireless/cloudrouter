#!/usr/bin/env bash

# ensure we got everything we need to start building images
yum --assumeyes install \
    wget curl gnupg python git genisoimage \
    qemu-kvm qemu-img virt-manager libvirt libvirt-python \
    libvirt-client net-tools libguestfs-tools

# import the fedora gpg key to be used for image verification
curl https://getfedora.org/static/fedora.gpg | gpg --import
