#!/usr/bin/env bash

OS=$(echo ${OS-fedora} | tr '[:upper:]' '[:lower:]')
VERSION=${VERSION-20}
ARCH=${ARCH-x86_64}
PROFILE=$(echo ${PROFILE-minimal}  | tr '[:upper:]' '[:lower:]')
SCRIPT_HOME=${SCRIPT_HOME-$(dirname "${BASH_SOURCE[0]}")}
BUILD_DIR=${BUILD_DIR-$(pwd)}
RELEASE_RPM=${RELEASE_RPM-https://cloudrouter.org/repo/beta/x86_64/cloudrouter-release-latest.noarch.rpm}

VIRT_BUILDER_CMD=${VIRT_BUILDER_CMD-virt-builder}
BUILD_EXTRA_ARGS="${BUILD_EXTRA_ARGS}"
BUILD_EXTRA_ARGS_END="${BUILD_EXTRA_ARGS_END}"

# dynamic var
BUILDER=${OS}-${VERSION}
OUTPUT="${BUILD_DIR}/cloudrouter-${OS}-${PROFILE}.raw"
BUILD_LOG=${OUTPUT/.raw/.log}

function fail(){
    MSG=$1
    echo "[ERROR] ${MSG}"
    exit 1
}

# check for virt-builder
command -v ${VIRT_BUILDER_CMD} > /dev/null 2>&1 \
    || fail "virt-builder was not found; please install libguestfs-tools."

# check if the builder base is available
${VIRT_BUILDER_CMD} --list | grep ${BUILDER} > /dev/null \
    || fail "Builder image  ${BUILDER} not found."

PACKAGES=deltarpm
PACKAGE_LIST="${SCRIPT_HOME}/package-lists/${PROFILE}"
if [ -f "${PACKAGE_LIST}" ]; then
    PACKAGES="${PACKAGES}$(cat ${PACKAGE_LIST} | xargs -I {} echo -n ",{}")"
fi

# install any extra packages defined at runtime
if [ ! -z "${EXTRA_PACKAGES}" ]; then
    PACKAGES="${PACKAGES},${EXTRA_PACKAGES}"
fi

# see if there is any os specific action
COMMON_SCRIPT="${SCRIPT_HOME}/scripts/common.sh"
OS_SCRIPT="${SCRIPT_HOME}/scripts/${OS}.sh"

for SCRIPT in ${COMMON_SCRIPT} ${OS_SCRIPT}; do
    if [ -f "${SCRIPT}" ]; then
        BUILD_EXTRA_ARGS="${BUILD_EXTRA_ARGS} --run ${SCRIPT}"
    fi
done

# print some inf
echo "#####################"
echo "# BUILD INFORMATION #"
echo "#####################"
echo ""
echo "SCRIPT_HOME: ${SCRIPT_HOME}"
echo "BUILD_DIR: ${BUILD_DIR}"
echo "OUTPUT: ${OUTPUT}"
echo "LOG: ${BUILD_LOG}"
echo "BUILDER: ${BUILDER}"
echo "PROFILE: ${PROFILE}"
echo ""
echo "CloudRouter release RPM:"
echo "${RELEASE_RPM}"
echo ""
echo "Additional packages being installed:"
echo "${PACKAGES}"

if [ ! -z "${BUILD_EXTRA_ARGS}" ] || [ ! -z "${BUILD_EXTRA_ARGS_END}" ]; then
    echo ""
    echo "Extra arguments passed to ${VIRT_BUILDER_CMD}:"
    echo "${BUILD_EXTRA_ARGS} ${BUILD_EXTRA_ARGS_END}"
fi

echo ""
echo "#####################"
echo ""

# prepare the image
${VIRT_BUILDER_CMD} ${BUILDER} \
    --arch ${ARCH} \
    --root-password locked:disabled \
    ${BUILD_EXTRA_ARGS} \
    --run-command "yum -y install ${RELEASE_RPM}" \
    --run-command "rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CLOUDROUTER" \
    --install "${PACKAGES}" \
    --update \
    --format raw \
    --output ${OUTPUT} \
    --selinux-relabel \
    --run-command "rpm -qa" \
    --run-command "yum -y clean all" \
    ${BUILD_EXTRA_ARGS_END} | tee ${BUILD_LOG}

# TODO: figure out how to extract manifest
# cat ${BUILD_LOG} | grep -v "${RELEASE_RPM}" | grep "\.rpm$" \
#     > ${OUTPUT/.raw/.manifest}

xz --verbose --force ${BUILD_DIR}/*.raw
