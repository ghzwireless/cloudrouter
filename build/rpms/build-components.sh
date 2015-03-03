#!/usr/bin/env bash

COMPONENTS_DIR=${COMPONENTS_DIR-./components}

RPM_BUILD_SOURCES=$(rpmbuild --eval '%{_sourcedir}')
RPM_BUILD_RPMS=$(rpmbuild --eval '%{_rpmdir}')
RPM_BUILD_SRPMS=$(rpmbuild --eval '%{_srcrpmdir}')

mkdir -p ${RPM_BUILD_SOURCES}

for COMPONENT in "$@"; do
    COMPONENT_DIR=${COMPONENTS_DIR}/${COMPONENT}
    LOG_FILE=build-${COMPONENT}.log

    if [ -d ${COMPONENT_DIR} ]; then
        # move all local patches
        find ${COMPONENT_DIR} ! -name "sources" -a ! -name "*.spec" \
            -exec cp {} ${RPM_BUILD_SOURCES}/. \;

        # fetch all externam patches/sources
        2>&1 find ${COMPONENT_DIR} -name "*.spec" \
            -exec spectool --sourcedir --get-files {} \; \
            -exec rpmbuild -ba --clean {} \; | tee ${LOG_FILE}

        # lets pull out the rpms created
        find ${RPM_BUILD_RPMS} -name "${COMPONENT}*.rpm" \
            -exec mv {} . \;
        find ${RPM_BUILD_SRPMS} -name "${COMPONENT}*.rpm" \
            -exec mv {} . \;

    fi
done
