#!/bin/bash
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   bootstrap_cloudrouter.sh
#   Description: Automated installer for KVM guest of cloudrouter
#   Author: Jeremy Agee <jagee@iix.net>
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
# Copyright (C) 2015 IIX Inc.
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

LIBVIRT_STORE="/var/lib/libvirt/images"
GUEST_VCPU="2"
GUEST_RAM="2048"

if [ ! -n "$CLOUDROUTER_USERPASS" ]; then
    CLOUDROUTER_USERPASS="CloudRouter"
fi

if [ ! -n "$CLOUDROUTER_URL" ]; then
    export CLOUDROUTER_URL="https://repo.cloudrouter.org/beta/images/"
fi

if [ ! -n "$CLOUDROUTER_NETWORK_IP" ]; then
    CLOUDROUTER_NETWORK_IP="192.168.122.100"
    CLOUDROUTER_NETWORK_NETMASK="255.255.255.0"
    CLOUDROUTER_NETWORK_NETWORK="192.168.122.0"
    CLOUDROUTER_NETWORK_BROADCAST="192.168.122.255"
    CLOUDROUTER_NETWORK_DEFAULT_ROUTE="192.168.122.1"
    CLOUDROUTER_NETWORK_DNS1="192.168.122.1"
    CLOUDROUTER_NETWORK_DNS2="8.8.8.8"
fi

CREATECLOUDINIT="1"
DOWNLOADIMAGE="1"
KEEPBASEIMAGE="0"

for cmd in "genisoimage xz sha512sum virt-install curl ssh-keygen"; do
    type $cmd > /dev/null 2>&1 \
        || { echo >&2 "[ERROR] $cmd command not found."; exit 1; }
done

function usage(){
	echo "usage: $0 cloudrouter_image"
	echo "optional: -si | --skipcloudinit"
	echo "optional: -sd | --skipdownload"
	echo "optional: -ki | --keepbaseimage"
}

if [ -n "$1" ]; then
    export CLOUDROUTER_IMAGE=$1; shift
    export CLOUDROUTER_SHORTNAME=${CLOUDROUTER_IMAGE%%.*}
else
    	usage
	exit 1
fi

while [ "$1" != "" ]; do
	case $1 in
		-si | --skipcloudinit )
			echo "[INFO] Skipping creation of cloud-init iso"
			shift
			CREATECLOUDINIT="0"
			;;
		-sd | --skipdownload )
			echo "[INFO] Skipping download of cloudrouter image"
			shift
			DOWNLOADIMAGE="0"
			;;
		-ki | --keepbaseimage )
			echo "[INFO] Keeping original xz base image"
			shift
			KEEPBASEIMAGE="1"
			;;
		-h | --help )
			usage
			exit
			;;
		* )
			usage
			exit 1
	esac
done

if [ ! -n "$WORKING_DIR" ]; then
    WORKING_DIR=$(mktemp --directory)
    CLOUDROUTER_PRIKEY=${WORKING_DIR}/${CLOUDROUTER_SHORTNAME}_rsa
    CLOUDROUTER_PUBKEY=${WORKING_DIR}/${CLOUDROUTER_SHORTNAME}_rsa.pub
fi

function make-ssh-keys(){
    echo "[INFO] Generating user ssh keys ..."
    ssh-keygen -f ${CLOUDROUTER_PRIKEY} -t rsa -N ''
    chmod 700 ${WORKING_DIR}
    chmod 600 ${WORKING_DIR}/*
    if [ ! -f "${CLOUDROUTER_PRIKEY}" ] && [ ! -f "${CLOUDROUTER_PUBKEY}" ]; then
        echo >&2 "[ERROR] private/pub key files could not be found at ${SSH_KEY_DIR}"
    fi
}

function make-cloud-init-iso(){
    echo "[INFO] Generating cloud-init iso ..."

    cat > ${WORKING_DIR}/user-data << EOF
#cloud-config
password: ${CLOUDROUTER_USERPASS}
ssh_pwauth: True
chpasswd: { expire: False }
ssh_authorized_keys:
  - $(cat ${CLOUDROUTER_PUBKEY})
bootcmd:
  - echo "DNS1=${CLOUDROUTER_NETWORK_DNS1}" >> /etc/sysconfig/network-scripts/ifcfg-eth0
  - echo "DNS2=${CLOUDROUTER_NETWORK_DNS2}" >> /etc/sysconfig/network-scripts/ifcfg-eth0
runcmd:
  - ifdown eth0
  - ifup eth0
EOF
    cat > ${WORKING_DIR}/meta-data << EOF
instance-id: ${CLOUDROUTER_SHORTNAME}
local-hostname: ${CLOUDROUTER_SHORTNAME}
network-interfaces: |
  auto eth0
  iface eth0 inet static
  address ${CLOUDROUTER_NETWORK_IP}
  network ${CLOUDROUTER_NETWORK_NETWORK} 
  netmask ${CLOUDROUTER_NETWORK_NETMASK}
  broadcast ${CLOUDROUTER_NETWORK_BROADCAST}
  gateway ${CLOUDROUTER_NETWORK_DEFAULT_ROUTE}
  dns-nameservers ${CLOUDROUTER_NETWORK_DNS1}
  dns-search localdomain
EOF

    genisoimage \
        -output ${WORKING_DIR}/${CLOUDROUTER_SHORTNAME}-cloud-init.iso \
        -volid cidata \
        -joliet \
        -rock ${WORKING_DIR}/user-data ${WORKING_DIR}/meta-data
    chmod 744 ${WORKING_DIR}/${CLOUDROUTER_SHORTNAME}-cloud-init.iso

    rm -f ${WORKING_DIR}/user-data ${WORKING_DIR}/meta-data
    sudo mv ${WORKING_DIR}/${CLOUDROUTER_SHORTNAME}-cloud-init.iso ${LIBVIRT_STORE}
}

function download-cloudrouter-image(){
    if curl -k ${CLOUDROUTER_URL}/${CLOUDROUTER_IMAGE} --head --silent|grep -q "HTTP/1.1 200 OK"; then 
        sudo curl -k -s -o ${LIBVIRT_STORE}/${CLOUDROUTER_IMAGE} ${CLOUDROUTER_URL}/${CLOUDROUTER_IMAGE}

    else
        echo "[ERROR] image did not exist ( ${CLOUDROUTER_URL}/${CLOUDROUTER_IMAGE} )"; exit 1
    fi
    if curl -k ${CLOUDROUTER_URL}/${CLOUDROUTER_IMAGE}.checksum.txt --head --silent|grep -q "HTTP/1.1 200 OK"; then
        sudo curl -k -s -o ${LIBVIRT_STORE}/${CLOUDROUTER_SHORTNAME}.checksum.txt ${CLOUDROUTER_URL}/${CLOUDROUTER_SHORTNAME}.checksum.txt
        FILE_SHA512SUM=$(cat ${LIBVIRT_STORE}/${CLOUDROUTER_SHORTNAME}.checksum.txt|awk -F " " '{ print $1 }')
        IMG_SHA512SUM=$(sha512sum ${LIBVIRT_STORE}/${CLOUDROUTER_IMAGE}|awk -F " " '{ print $1 }')
        if [ "$FILE_SHA512SUM" == "$IMG_SHA512SUM" ]; then
            echo "[INFO] checksum on xz image and checksum.txt match"
        else
            echo "[ERROR] checksum on xz image and checksum.txt did not match"; exit 1
        fi
    else
        echo "[INFO] No checksum file to compare xz image with"
    fi
}

function extract-cloudrouter-image(){
    sudo xz -d -f $1 ${LIBVIRT_STORE}/${CLOUDROUTER_IMAGE}
}

function create-libvirt-kvm-guest(){
    sudo virt-install --accelerate --hvm --os-type linux --os-variant fedora20 --name ${CLOUDROUTER_SHORTNAME} --vcpus ${GUEST_VCPU} --ram ${GUEST_RAM} --import --disk bus=virtio,path=${LIBVIRT_STORE}/${CLOUDROUTER_IMAGE%.*} --disk device=cdrom,bus=ide,path=${LIBVIRT_STORE}/${CLOUDROUTER_SHORTNAME}-cloud-init.iso --network default,model=virtio --noautoconsole
}

if [ "$CREATECLOUDINIT" -eq "1" ]; then
    make-ssh-keys
	make-cloud-init-iso
fi
if [ "$DOWNLOADIMAGE" -eq "1" ]; then
	download-cloudrouter-image
fi
if [ "$KEEPBASEIMAGE" -eq "1" ]; then
	extract-cloudrouter-image "-k"
else
	extract-cloudrouter-image
    sudo rm -f ${LIBVIRT_STORE}/${CLOUDROUTER_SHORTNAME}.checksum.txt
fi

create-libvirt-kvm-guest
