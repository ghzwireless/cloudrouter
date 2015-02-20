#!/usr/bin/env bash

TMPDIR=${TMPDIR-/tmp}
BUILD_DIR=$(mktemp --directory --tmpdir=${TMPDIR} cloudrouter.build.image.XXXXXXXXXX)

# since we use qemu; fix permissions on build directory
chmod 770 ${BUILD_DIR}
chown $(whoami):qemu ${BUILD_DIR}

# define stuff used in the script for ease
FEDORA_ARCH=${FEDORA_ARCH-x86_64}
FEDORA_VERSION=${FEDORA_VERSION-20}
FEDORA_RELEASE=${FEDORA_RELEASE-20131211.1}

FEDORA_URL_PREFIX=https://dl.fedoraproject.org/pub/fedora/linux/releases/${FEDORA_VERSION}/Images/${FEDORA_ARCH}
FEDORA_IMAGE_RAW=Fedora-${FEDORA_ARCH}-${FEDORA_VERSION}-${FEDORA_RELEASE}-sda.raw
FEDORA_IMAGE=${FEDORA_IMAGE_RAW}.xz
FEDORA_CHECKSUM=Fedora-Images-${FEDORA_ARCH}-${FEDORA_VERSION}-CHECKSUM
FEDORA_IMAGE_URL=${FEDORA_URL_PREFIX}/${FEDORA_IMAGE}
FEDORA_CHECKSUM_URL=${FEDORA_URL_PREFIX}/${FEDORA_CHECKSUM}
CHECKSUM_FILE=${BUILD_DIR}/${FEDORA_CHECKSUM}
FEDORA_USER=fedora

BUILD_IMAGE_RAW=${BUILD_DIR}/cloudrouter-build.raw
BUILD_IMAGE_TMP=${BUILD_IMAGE_RAW/.raw/-tmp.raw}
SSH_KEY=${BUILD_DIR}/build_rsa
CLOUD_INIT_DIR=${BUILD_DIR}/cloud-init
CLOUD_INIT_ISO=${BUILD_DIR}/init.iso
VIRT_HOSTNAME=cloudrouter-build
VIRT_ARCH=${FEDORA_ARCH}
VIRT_NETWORK=${VIRT_HOSTNAME}
VIRT_BUILD_XML_SRC=CloudRouter-build.xml
VIRT_BUILD_XML=${BUILD_DIR}/cloudrouter-build.xml
VIRT_NETWORK_XML=${BUILD_DIR}/cloudrouter-build-network.xml

function cr-virsh-network-destroy(){
    echo "INFO: Attempting to destroy network ${VIRT_NETWORK} ... "
    virsh net-undefine ${VIRT_NETWORK} \
        && virsh net-destroy ${VIRT_NETWORK}
}

function cr-virsh-network-create(){
    cr-virsh-network-destroy

    # Setup network required
    cat > ${VIRT_NETWORK_XML} << EOF
<network>
  <name>${VIRT_NETWORK}</name>
  <domain name='${VIRT_NETWORK}' />
  <forward mode='nat' />
  <ip address='192.168.110.1' netmask='255.255.255.0'>
    <dhcp>
      <range start='192.168.110.128' end='192.168.110.254' />
    </dhcp>
  </ip>
</network>
EOF

    virsh net-define ${VIRT_NETWORK_XML}
    virsh net-autostart ${VIRT_NETWORK}
    virsh net-start ${VIRT_NETWORK}
}

function cr-virsh-destroy(){
    echo "INFO: Attempting to destroy ${VIRT_HOSTNAME} ... "
    if [ ! -z ${GUEST_IP_ADDR} ]; then
        ${SSH_CMD} 'sudo yum clean all'

        # clear cloud-init stuff
        ${SSH_CMD} 'sudo rm -rf /var/lib/cloud/instances /tmp/* /etc/sudoers.d/*cloud-init*'

        # clear ssh authorzied keys last
        ${SSH_CMD} '[[ -f ~/.ssh/authorized_keys ]] && echo "" > ~/.ssh/authorized_keys'
    fi
    virsh destroy ${VIRT_HOSTNAME}
}

function cr-virsh-create(){
    cr-virsh-destroy
    echo "INFO: Attempting to create ${VIRT_HOSTNAME} ... "
    virsh create ${VIRT_BUILD_XML}
    echo "INFO: Waiting for guest to boot up ... " && sleep 300
    cr-virsh-set-ip
}

function cr-build-setup()
{
    # generate temporary ssh key
    ssh-keygen -t rsa -C "build" -f ${SSH_KEY} -q -N ""

    # Prepare libvirt xml configuration
    cp ${VIRT_BUILD_XML_SRC} ${VIRT_BUILD_XML}
    sed -i s="BUILD_IMAGE_RAW"="${BUILD_IMAGE_RAW}"=g ${VIRT_BUILD_XML}
    sed -i s="CLOUD_INIT_ISO"="${CLOUD_INIT_ISO}"=g ${VIRT_BUILD_XML}
    sed -i s="VIRT_HOSTNAME"="${VIRT_HOSTNAME}"=g ${VIRT_BUILD_XML}
    sed -i s="VIRT_NETWORK"="${VIRT_NETWORK}"=g ${VIRT_BUILD_XML}
    sed -i s="VIRT_ARCH"="${VIRT_ARCH}"=g ${VIRT_BUILD_XML}

    cr-virsh-network-create
}

function cr-build-cleanup()
{
    cr-virsh-network-destroy
    # remove any temporary files created
    rm -rf *.xml \
        ${CLOUD_INIT_ISO} \
        ${SSH_KEY}.* \
        ${BUILD_IMAGE_RAW} \
        ${CLOUD_INIT_DIR}
}

# to be used only once the guest is up and running
function cr-virsh-set-ip(){
    # Get the VM's IP
    GUEST_IP_ADDR=$(arp -e \
        | grep "`virsh dumpxml ${VIRT_HOSTNAME} | grep "mac address"|sed "s/.*'\(.*\)'.*/\1/g"`" \
        | cut -d ' ' -f1)

    # ssh command
    SSH_CMD="ssh -t -i ${SSH_KEY} -o StrictHostKeyChecking=no fedora@$GUEST_IP_ADDR"

    # Clear old ssh known hosts
    sed -i /"${GUEST_IP_ADDR}"/d ~/.ssh/known_hosts
}

#
# helper function to extract named image snapshots of raw files fomr live guests
#
# WARNING: SSH_CMD is only defined later once IP address of guest is extracted.
#
function extract-named-image()
{
    # Generate manifest and clean /tmp in guest
    ${SSH_CMD} 'rpm -qa | sort' > ${BUILD_DIR}/manifest-${1}.txt

    # undefine before blockcopying
    virsh dumpxml ${VIRT_HOSTNAME} > ${VIRT_BUILD_XML}
    #virsh undefine ${VIRT_HOSTNAME}

    # this  is not possible  on centos 7 with current QEMU binary
    # see: https://bugs.launchpad.net/nova/+bug/1381153
    # error: unsupported configuration: block copy is not supported with this QEMU binary

    ## blockcopy to snapshot storage
    # virsh blockcopy --wait --finish --verbose \
    #    --domain ${VIRT_HOSTNAME} \
    #    ${BUILD_IMAGE_RAW} ${BUILD_IMAGE_RAW/.raw/-${1}.raw}

    ## redefine to ensure persistance
    # virsh define ${VIRT_BUILD_XML}

    # workaround: ugly and adds 5 minutes wait
    virsh destroy ${VIRT_HOSTNAME}
    cp ${BUILD_IMAGE_RAW} ${BUILD_IMAGE_RAW/.raw/-${1}.raw}
    cr-virsh-create
}

function cr-virsh-init-iso(){
    # Create a cloud-init ISO image to inject build SSH_KEY
    mkdir ${CLOUD_INIT_DIR}
    cat > ${CLOUD_INIT_DIR}/user-data << EOF
#cloud-config
write_files:
    - content: |
        # disable requiretty for ${FEDORA_USER}
        Defaults:${FEDORA_USER} !requiretty
      path: /etc/sudoers.d/90-cloud-init-tty
      permissions: '0440'
ssh_authorized_keys:
    - $(cat ${SSH_KEY}.pub)
EOF

    cat > ${CLOUD_INIT_DIR}/meta-data << EOF
instance-id: ${VIRT_HOSTNAME}
local-hostname: ${VIRT_HOSTNAME}
EOF

    genisoimage \
        -output ${CLOUD_INIT_ISO} \
        -volid cidata \
        -joliet \
        -rock ${CLOUD_INIT_DIR}/user-data ${CLOUD_INIT_DIR}/meta-data
    chmod 777 ${CLOUD_INIT_ISO}
}

# Get a fresh checksum copy for verification
wget -O ${CHECKSUM_FILE} ${FEDORA_CHECKSUM_URL}
gpg --verify-files ${CHECKSUM_FILE} || \
    { >&2 echo "ERROR: Invalid checksum file ${CHECKSUM_FILE} downloaded." \
        && exit 1 ; }

if [ ! -f ${FEDORA_IMAGE} ]; then
    wget ${FEDORA_IMAGE_URL}
fi

if ! sha256sum -c ${CHECKSUM_FILE} 2> /dev/null \
    | grep "${FEDORA_IMAGE}: OK" > /dev/null; then
    >&2 echo "ERROR: Invalid image checksum for ${FEDORA_IMAGE}"
    exit 1
fi

# setup build
cr-build-setup

# remove raw image if it exists
rm -rf ${FEDORA_IMAGE_RAW}

# decompress raw image but keep the original for future verification
unxz --keep ${FEDORA_IMAGE}
mv ${FEDORA_IMAGE_RAW} ${BUILD_IMAGE_TMP}
chmod 777 ${BUILD_IMAGE_TMP}

# Resize the image (+1 GB)
truncate -r ${BUILD_IMAGE_TMP} ${BUILD_IMAGE_RAW}
truncate -s +1G ${BUILD_IMAGE_RAW}
virt-resize --expand /dev/sda1 ${BUILD_IMAGE_TMP} ${BUILD_IMAGE_RAW}
rm -f ${BUILD_IMAGE_TMP}

# Use virt-edit to add the no_timer_check kernel parameter. 
# This is necessary for the image to load under pure QEMU (no KVM).
virt-edit -a "${BUILD_IMAGE_RAW}" \
    --format=raw /boot/extlinux/extlinux.conf \
    -e 's/console=tty1/no_timer_check console=tty1/'

# create an init iso with build SSH_KEY
cr-virsh-init-iso

# Spin up the VM and wait 5 minutes for it to boot
cr-virsh-create

# install deltarpms
$SSH_CMD "sudo yum --assumeyes install deltarpm"

# update base
$SSH_CMD "sudo yum --assumeyes update"

# workaroud tty issue when running script from host
$SSH_CMD "echo $(base64 -w0 fedora-cloudrouter-setup.sh) | base64 -d | sudo bash"

# extract minimal
extract-named-image minimal

# install additional packages for full distribution and extract full image
${SSH_CMD} "sudo yum -y install $(cat packages-full.list | tr "\\n" " ")"
extract-named-image full

# Shutdown VM and cleanup
cr-virsh-destroy
cr-build-cleanup

# xz compress
xz --verbose ${BUILD_DIR}/*.raw
