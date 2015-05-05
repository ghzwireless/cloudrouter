#!/usr/bin/env bash
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#   make-cloud-init-iso.sh
#   Description: Create a cloud-init iso for cloudrouter
#   Version: 1.1
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

if [ ! -n "${HOST}" ]; then
    HOST="localhost"
fi

if [ ! -n "${WORKING_DIR}" ]; then
    WORKING_DIR=$(mktemp --directory)
fi

if [ ! -n "${PRIKEY}" ] && [ ! -n "${PUBKEY}" ]; then
    PRIKEY="${WORKING_DIR}/cloudrouter_rsa"
    PUBKEY="${PRIKEY}.pub"
fi

for cmd in genisoimage ssh-keygen; do
    type $cmd > /dev/null 2>&1 \
        || { echo >&2 "[ERROR] $cmd command not found."; exit 1; }
done

SKIPSSHKEY="0"
SKIPUSERPASS="0"
GENERATESSHKEY="1"
USERPASS=${WORKING_DIR##*.}

function usage() {
	echo "usage: $0"
	echo "optional: -pw [password] | --password [password]"
    echo "optional: -np | --nopassword"
    echo "optional: -nk | --nosshkey"
    echo "optional: -k [/path/to/ssh/key.pub] | --key [/path/to/ssh/key.pub]"
}

function make-ssh-keys() {
    echo "[INFO] Generating rsa ssh keys ..."
    ssh-keygen -f ${PRIKEY} -t rsa -N ''
    if [ ! -f "${PRIKEY}" ] && [ ! -f "${PUBKEY}" ]; then
        echo >&2 "[ERROR] private/pub key files could not be found at ${WORKING_DIR}"
    fi
}

function make-cloud-init-iso() {
    echo "[INFO] Generating cloudrouter cloud-init iso ..."

    cat > ${WORKING_DIR}/user-data << EOF
#cloud-config
EOF

if [ "$SKIPUSERPASS" -eq "0" ]; then
    cat >> ${WORKING_DIR}/user-data << EOF
password: ${USERPASS}
ssh_pwauth: True
chpasswd: { expire: False }
EOF
fi

if [ "$SKIPSSHKEY" -eq "0" ]; then
    cat >> ${WORKING_DIR}/user-data << EOF
ssh_authorized_keys:
  - $(cat ${PUBKEY})
EOF
fi
    cat > ${WORKING_DIR}/meta-data << EOF
instance-id: ${HOST}
local-hostname: ${HOST}
EOF
    genisoimage \
        -quiet \
        -output ${WORKING_DIR}/cloudrouter-init.iso \
        -volid cidata \
        -joliet \
        -input-charset utf-8 \
        -rock ${WORKING_DIR}/user-data ${WORKING_DIR}/meta-data
    rm -f ${WORKING_DIR}/user-data ${WORKING_DIR}/meta-data
}

while [ "$1" != "" ]; do
	case $1 in
		-pw | --password )
			echo "[INFO] Using supplied password"
			shift
            if [ -n "$1" ]; then
                USERPASS=$1
            else
                echo "[ERROR] No password specified";exit 1
            fi
            shift
			;;
        -np | --nopassword )
            echo "[INFO] No cloudrouter user password"
            SKIPUSERPASS="1"
            shift
            ;;
		-nk | --nosshkey )
			echo "[INFO] Skipping ssh key creation"
			shift
			SKIPSSHKEY="1"
			;;
        -k | --key )
            echo "[INFO] Using supplied ssh key"
            shift
            PUBKEY=$1
            GENERATESSHKEY="0"
            shift
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

if [ "${SKIPSSHKEY}" -eq "0" ] && [ "${GENERATESSHKEY}" -eq "0" ] && [ ! -f ${PUBKEY} ]; then
    echo >&2 "[ERROR] ${PUBKEY} key file not found"; exit 1
fi

if [ "${SKIPSSHKEY}" -eq "0" ] && [ "${GENERATESSHKEY}" -eq "1" ]; then
    make-ssh-keys
fi

make-cloud-init-iso
if [ "${SKIPUSERPASS}" -eq "0" ]; then
    echo "[INFO] cloudrouter user password: ${USERPASS}"
fi
echo "[INFO] Cloudrouter data writen to ${WORKING_DIR}"
