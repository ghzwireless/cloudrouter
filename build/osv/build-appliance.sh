#!/usr/bin/env bash

# defaults
DEFAULT_APPS="opendaylight,cloud-init,monitoring-agent"
DEFAULT_DESC="OpenDaylight Helium SR3 on OSv"

OSV_HOME=${OSV_HOME-$(pwd)}
APPLIANCE_NAME="${APPLIANCE_NAME-unknown}"
APPLIANCE_DESC=${APPLIANCE_DESC-${DEFAULT_DESC}}
APPS_CSV=${APPS_CSV-${DEFAULT_APPS}}

# clean any previous build artifacts
[[ ! -z "${OSV_CLEAN}" ]] && ( cd ${OSV_HOME} && make clean )

# clean apps if possible
IFS_OLD=${IFS}
IFS=,
APPS=( ${APPS_CSV} )
IFS=${IFS_OLD}
for APP in "${APPS[@]}"; do
    APP_DIR="${OSV_HOME}/apps/${APP}"
    [[ -f "${APP_DIR}/Makefile" ]] && { 
        echo "[build/osv] Cleaning ${APP_DIR} ..." \
            && ( cd ${APP_DIR} && make clean ); 
    }
done

# build osv
( cd ${OSV_HOME} && make )

# echo some stuff
echo "##################"
echo "# Appliance Info #"
echo "##################"
echo ""
echo "Name: ${APPLIANCE_NAME}"
echo "Desc: ${APPLIANCE_DESC}"
echo "Apps: ${APPS_CSV}"
echo ""
echo "##################"

# create the image
( cd ${OSV_HOME} \
    && ./scripts/build-vm-img ${APPLIANCE_NAME} ${APPS_CSV} "${APPLIANCE_DESC}" 
)
