#!/bin/sh
BUILD_SERVER_PROTO=https
BUILD_SERVER_HOST=104.197.15.26
BUILD_SERVER_PORT=8443
BUILD_SERVER_API_PATH=/job/cloudrouter-build-rpms/lastSuccessfulBuild/api/json
BUILD_SERVER_URL=${BUILD_SERVER_PROTO}://${BUILD_SERVER_HOST}:${BUILD_SERVER_PORT}${BUILD_SERVER_API_PATH}
CURL_CMD="curl --insecure -s"
CR_SIGNING_DIR=~/.crsigning
NOTIFICATION_EMAIL=djorm@iix.net

if [ ! -d ${CR_SIGNING_DIR} ] ; then
	# First run, setup...
	echo "First run"
	mkdir ${CR_SIGNING_DIR}
	${CURL_CMD} ${BUILD_SERVER_URL} | jq '.number' > ${CR_SIGNING_DIR}/lastBuild
fi

# Compare last locally known build to last successful remote build
LAST_BUILD_LOCAL=`cat ~/.crsigning/lastBuild`
${CURL_CMD} ${BUILD_SERVER_URL} | jq '.number' > ${CR_SIGNING_DIR}/lastBuild
LAST_BUILD_REMOTE=`cat ~/.crsigning/lastBuild`
if [ ${LAST_BUILD_REMOTE} -gt ${LAST_BUILD_LOCAL} ] ; then
	# New build available, download all the artifacts
	BUILD_URL=`${CURL_CMD} ${BUILD_SERVER_URL} | jq -r '.url'`
	mkdir ${CR_SIGNING_DIR}/${LAST_BUILD_REMOTE}
	${CURL_CMD} ${BUILD_SERVER_URL} | jq -r '.artifacts[]' | grep fileName | while read -r line; do
		FILE_NAME=`echo ${line} | cut -d '"' -f4`
		${CURL_CMD} "${BUILD_URL}/artifact/${FILE_NAME}" -o ${CR_SIGNING_DIR}/${LAST_BUILD_REMOTE}/${FILE_NAME}
		echo "Downloaded artifact ${CR_SIGNING_DIR}/${LAST_BUILD_REMOTE}/${FILE_NAME}"
	done
	SIGNING_TARGETS=`ls ${CR_SIGNING_DIR}/${LAST_BUILD_REMOTE}/*.rpm`
	echo "The following artifacts have been downloaded, ready for signing: ${SIGNING_TARGETS}" | mail -s "CloudRouter artifacts are ready to sign" ${NOTIFICATION_EMAIL}
fi
