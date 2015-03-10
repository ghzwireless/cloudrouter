#!/usr/bin/env bash

PUB=${PUB-~/.ssh/id_rsa.pub}
USER=${USER-cloud-user}
HOST=${HOST-localhost}

if [ ! -f "${PUB}" ]; then
    echo >&2 "[ERROR] Cloud not find pub key file at ${PUB}"
fi

type genisoimage > /dev/null 2>&1 \
    || { echo >&2 "[ERROR] genisoimage command not found."; exit 1; }

function make-cloud-init-iso(){
    CLOUD_INIT_DIR=$(mktemp --directory)

    echo "[INFO] Generating cloud-init iso ..."

    cat > ${CLOUD_INIT_DIR}/user-data << EOF
#cloud-config
ssh_authorized_keys:
    - $(cat ${PUB})
EOF
    cat > ${CLOUD_INIT_DIR}/meta-data << EOF
instance-id: ${HOST}
local-hostname: ${HOST}
EOF

    genisoimage \
        -output cloud-init.iso \
        -volid cidata \
        -joliet \
        -rock ${CLOUD_INIT_DIR}/user-data ${CLOUD_INIT_DIR}/meta-data
    chmod 777 cloud-init.iso

    rm -rf ${CLOUD_INIT_DIR}
}

make-cloud-init-iso