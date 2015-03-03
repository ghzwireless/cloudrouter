#!/usr/bin/env bash

function fail(){
    MSG=$1
    echo "[ERROR] ${MSG}"
    exit 1
}

if [ -z ${RH_CSP_USERNAME} ]; then
    echo -n "Red Hat Portal Username: "
    read RH_CSP_USERNAME
fi

# TODO: probably do a better job of this
if [ -z ${RH_CSP_PASSWORD} ]; then
    echo -n "Red Hat Portal Password: "
    read -s RH_CSP_PASSWORD
fi

OS=$(echo ${OS-rhel} | tr '[:upper:]' '[:lower:]')
VERSION=${VERSION-7.0}
ARCH=${ARCH-x86_64}
VIRT_BUILDER_CMD=${VIRT_BUILDER_CMD-virt-builder}
REPO_MANAGER_SCRIPT=${REPO_MANAGER_CMD-$(dirname "${BASH_SOURCE[0]}")/virt-builder-repoman}
FORMAT=${FORMAT-qcow2}
REPO=${REPO-jenkins}
SUFFIX=${SUFFIX-""}

BUILDER=${OS}-${VERSION}

if [ -z "$SUFFIX" ]; then
    OUTPUT="${BUILDER}.${FORMAT}"
else
    OUTPUT="${BUILDER}-${SUFFIX}.${FORMAT}"
fi
BUILD_LOG=${OUTPUT/.${FORMAT}/.log}

# check if the builder base is available
{ ${VIRT_BUILDER_CMD} --list | grep ${BUILDER}-${SUFFIX} > /dev/null \
        && BASE=${BUILDER}-${SUFFIX}; } \
    || { ${VIRT_BUILDER_CMD} --list | grep ${BUILDER} > /dev/null \
        && BASE=${BUILDER}; } \
    || fail "Builder image  ${BUILDER} not found."

${VIRT_BUILDER_CMD} ${BASE} \
    --arch ${ARCH} \
    --root-password locked:disabled \
    --run-command "subscription-manager register --username \"${RH_CSP_USERNAME}\" --password \"${RH_CSP_PASSWORD}\" --auto-attach" \
    --update \
    --run-command "yum -y clean all" \
    --run-command "subscription-manager remove --all" \
    --run-command "subscription-manager unregister" \
    --run-command "subscription-manager clean" \
    --format ${FORMAT} \
    --output ${OUTPUT} \
    --selinux-relabel

${REPO_MANAGER_SCRIPT} -o ${OS} -v ${VERSION} -r ${REPO} -f ${FORMAT} \
    -s ${SUFFIX} add ${OUTPUT}
