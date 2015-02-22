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
CR_REL_RPM="https://cloudrouter.org/repo/beta/x86_64/cloudrouter-release-1-1.noarch.rpm"

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

VIRSH_WAIT_CREATE=${VIRSH_WAIT_CREATE-300}
VIRSH_WAIT_DESTROY=${VIRSH_WAIT_DESTROY-10}
VIRSH_WAIT_SHUTDOWN=${VIRSH_WAIT_SHUTDOWN-${VIRSH_WAIT_DESTROY}}

function cr-build-log(){
    echo "$(date) [cr-build] $1"
}

# spit out configuration
cr-build-log "FEDORA_ARCH=${FEDORA_ARCH}"
cr-build-log "FEDORA_VERSION=${FEDORA_VERSION}"
cr-build-log "FEDORA_RELEASE=${FEDORA_RELEASE}"
cr-build-log "CR_REL_RPM=${CR_REL_RPM}"
cr-build-log "VIRSH_WAIT_CREATE=${VIRSH_WAIT_CREATE}"
cr-build-log "VIRSH_WAIT_DESTROY=${VIRSH_WAIT_DESTROY}"
cr-build-log "VIRSH_WAIT_SHUTDOWN=${VIRSH_WAIT_SHUTDOWN}"
[[ ! -z ${DISABLE_BASE_UPDATE} ]] \
    && cr-build-log "DISABLE_BASE_UPDATE set; base update disabled"


function cr-build-error(){
    >&2 cr-build-log "[ERROR] $1"
    cr-build-cleanup
    exit 1
}

function cr-virsh-network-destroy(){
    virsh net-list | grep ${VIRT_NETWORK} > /dev/null \
        && { cr-build-log "Destroying network ${VIRT_NETWORK}"; \
        virsh net-undefine ${VIRT_NETWORK}; \
        virsh net-destroy ${VIRT_NETWORK}; }
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
    cr-build-log "Creating network named ${VIRT_NETWORK} ..."
    virsh net-define ${VIRT_NETWORK_XML}
    virsh net-autostart ${VIRT_NETWORK}
    virsh net-start ${VIRT_NETWORK}
    cr-build-log "Network creation completed."
}

function cr-virsh-shutdown(){
    if ping -c1 "${GUEST_IP_ADDR}"  > /dev/null 2>&1; then
        cr-build-log "Guest IP active, cleaning guest ..."
        ${SSH_CMD} 'sudo yum clean all'

        # clear cloud-init stuff
        ${SSH_CMD} 'sudo rm -rf /var/lib/cloud/instances /tmp/* /etc/sudoers.d/*cloud-init*'

        # clear ssh authorzied keys last
        ${SSH_CMD} '[[ -f ~/.ssh/authorized_keys ]] && echo "" > ~/.ssh/authorized_keys'
    fi

    virsh list | grep running | awk '{ print $2}' \
        | grep ${VIRT_HOSTNAME} > /dev/null \
        && { cr-build-log "Shutting down ${VIRT_HOSTNAME}"; \
        virsh shutdown ${VIRT_HOSTNAME} ; \
        sleep ${VIRSH_WAIT_SHUTDOWN}; }
}

function cr-virsh-destroy(){
    cr-virsh-shutdown
    virsh list | grep ${VIRT_HOSTNAME} > /dev/null \
        && { cr-build-log "Destroying domain ${VIRT_HOSTNAME}"; \
        virsh destroy ${VIRT_HOSTNAME}; \
        sleep ${VIRSH_WAIT_DESTROY}; \
        virsh list; }
}

function cr-virsh-create(){
    cr-virsh-destroy
    cr-build-log "Attempting to create domain ${VIRT_HOSTNAME} ... "
    virsh create ${VIRT_BUILD_XML}
    cr-build-log "Waiting for guest to boot up ... "
    sleep ${VIRSH_WAIT_CREATE}
    cr-virsh-set-ip
}

function cr-build-setup()
{
    # generate temporary ssh key
    cr-build-log "Generating temporary SSH key at ${SSH_KEY} ..."
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
    cr-build-log "Cleaning up build ..."
    cr-virsh-network-destroy
    cr-virsh-destroy
    # remove any temporary files created
    rm -rf *.xml \
        ${CLOUD_INIT_ISO} \
        ${SSH_KEY}.* \
        ${BUILD_IMAGE_RAW} \
        ${CLOUD_INIT_DIR}
    cr-build-log "Clean up completed."
}

# to be used only once the guest is up and running
function cr-virsh-set-ip(){
    # Get the VM's IP
    GUEST_IP_ADDR=$(arp -e \
        | grep "`virsh dumpxml ${VIRT_HOSTNAME} | grep "mac address"|sed "s/.*'\(.*\)'.*/\1/g"`" \
        | cut -d ' ' -f1)

    if [ -z "${GUEST_IP_ADDR}" ]; then
        cr-build-error "Could not retreive an IP address for the host."
    else
        cr-build-log "Found Guest IP address ${GUEST_IP_ADDR}"
    fi
    # ssh command
    SSH_CMD="ssh -t -i ${SSH_KEY} -o StrictHostKeyChecking=no fedora@$GUEST_IP_ADDR"
    cr-build-log "Generated SSH command: ${SSH_CMD}"

    # Clear old ssh known hosts
    if [ -f ~/.ssh/known_hosts ]; then
        cr-build-log "Clearing ${GUEST_IP_ADDR} from known hosts ..."
        sed -i /"${GUEST_IP_ADDR}"/d ~/.ssh/known_hosts
    fi
}

#
# helper function to extract named image snapshots of raw files fomr live guests
#
# WARNING: SSH_CMD is only defined later once IP address of guest is extracted.
#
function extract-named-image()
{
    cr-build-log "Extracting $1 image ..."
    # Generate manifest and clean /tmp in guest
    ${SSH_CMD} 'rpm -qa | sort' > ${BUILD_DIR}/manifest-${1}.txt

    # undefine before blockcopying
    #virsh dumpxml ${VIRT_HOSTNAME} > ${VIRT_BUILD_XML}
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
    cr-virsh-destroy
    cp ${BUILD_IMAGE_RAW} ${BUILD_IMAGE_RAW/.raw/-${1}.raw}
    # look for a second argument indicating if the guest should be recreated
    # if non-zero or empty guest is rescreated
    { [[ ! -z $2 ]] && [[ $2 -eq 0 ]] ; } || cr-virsh-create

    cr-build-log "Image extraction completed for $1."
}

function cr-virsh-init-iso(){
    cr-build-log "Generating cloud-init iso ..."
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
    cr-build-log "Using user-data with contents:"
    cat ${CLOUD_INIT_DIR}/user-data

    cat > ${CLOUD_INIT_DIR}/meta-data << EOF
instance-id: ${VIRT_HOSTNAME}
local-hostname: ${VIRT_HOSTNAME}
EOF

    cr-build-log "Using meta-data with contents:"
    cat ${CLOUD_INIT_DIR}/meta-data

    genisoimage \
        -output ${CLOUD_INIT_ISO} \
        -volid cidata \
        -joliet \
        -rock ${CLOUD_INIT_DIR}/user-data ${CLOUD_INIT_DIR}/meta-data
    chmod 777 ${CLOUD_INIT_ISO}
}

# Get a fresh checksum copy for verification
cr-build-log "Fetching a fresh Fedora base image checksum file ..."
wget -O ${CHECKSUM_FILE} ${FEDORA_CHECKSUM_URL}
gpg --verify-files ${CHECKSUM_FILE} || \
    cr-build-error "Invalid checksum file ${CHECKSUM_FILE} downloaded."

if [ ! -f ${FEDORA_IMAGE} ]; then
    wget ${FEDORA_IMAGE_URL}
fi

if ! sha256sum -c ${CHECKSUM_FILE} 2> /dev/null \
    | grep "${FEDORA_IMAGE}: OK" > /dev/null; then
    cr-build-error "Invalid image checksum for ${FEDORA_IMAGE}"
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
cr-build-log "Resizing base image backing file ..."
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
cr-build-log "Install detalrpm on guest ..."
${SSH_CMD} "sudo yum --assumeyes install deltarpm"

# remove stuff
${SSH_CMD} "sudo yum --assumeyes remove docker"

# update base
[[ ! -z ${DISABLE_BASE_UPDATE} ]] \
    || { cr-build-log "Update fedora base ..."; \
    ${SSH_CMD} "sudo yum --assumeyes update"; }

cr-build-log "Install Cloud Router repository ..."
${SSH_CMD} "sudo yum install --assumeyes ${CR_REL_RPM}"
${SSH_CMD} "sudo rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CLOUDROUTER"

# extract minimal
extract-named-image minimal

# install additional packages for full distribution and extract full image
${SSH_CMD} "sudo yum -y install $(cat packages-full.list | tr "\\n" " ")"
extract-named-image full 0

# Shutdown VM and cleanup
cr-virsh-destroy
cr-build-cleanup

# xz compress
cr-build-log "Compressing images (this will take a while)..."
xz --verbose ${BUILD_DIR}/*.raw
