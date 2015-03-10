#!/usr/bin/env bash

COMPONENTS_DIR=${COMPONENTS_DIR-./components}

RPM_BUILD_SOURCES=$(rpmbuild --eval '%{_sourcedir}')
RPM_BUILD_RPMS=$(rpmbuild --eval '%{_rpmdir}')
RPM_BUILD_SRPMS=$(rpmbuild --eval '%{_srcrpmdir}')

function usage(){
    echo "${BASH_SOURCE[0]} [-s|-h]"
    echo "    -s build only source rpms"
    echo "    -h help"
    exit 1
}

# handle opts
while getopts "sh" opt; do
    case $opt in
        s) SOURCE_ONLY=1;;
        h) usage;;
        \?) usage;;
    esac
done

shift $((OPTIND-1))

if [ ! -d ${COMPONENTS_DIR} ]; then
    echo >&2 "[ERROR] COMPONENTS_DIR=${COMPONENTS_DIR} does not exist." \
        "This can be set via the COMPONENTS_DIR environment variable."
    exit 1
fi

if [ $# -eq 0 ]; then
    COMPONENTS=( $(ls -d ${COMPONENTS_DIR}/* | xargs -I {} basename {}) )
else
    COMPONENTS=( $@ )
fi

RPM_BUILD_OPTS=""
if [ -z ${SOURCE_ONLY} ]; then
    RPM_BUILD_OPTS="${RPM_BUILD_OPTS} -ba"
else
    RPM_BUILD_OPTS="${RPM_BUILD_OPTS} -bs"
fi

mkdir -p ${RPM_BUILD_SOURCES}

for COMPONENT in "${COMPONENTS[@]}"; do
    COMPONENT_DIR=${COMPONENTS_DIR}/${COMPONENT}
    LOG_FILE=build-${COMPONENT}.log

    if [ -d ${COMPONENT_DIR} ]; then
        # move all local patches
        find ${COMPONENT_DIR} ! -name "sources" -a ! -name "*.spec" \
            -exec cp {} ${RPM_BUILD_SOURCES}/. \;

        # fetch all externam patches/sources
        2>&1 find ${COMPONENT_DIR} -name "*.spec" \
            -exec spectool --sourcedir --get-files {} \; \
            -exec rpmbuild ${RPM_BUILD_OPTS} --clean {} \; | tee ${LOG_FILE}

        # lets pull out the rpms created
        find ${RPM_BUILD_RPMS} -name "${COMPONENT}*.rpm" \
            -exec mv {} . \;
        find ${RPM_BUILD_SRPMS} -name "${COMPONENT}*.rpm" \
            -exec mv {} . \;

    fi
done
