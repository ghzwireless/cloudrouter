#!/bin/sh
BUILD_SERVER_PROTO=https
BUILD_SERVER_HOST=104.197.15.26
BUILD_SERVER_PORT=8443
BUILD_SERVER_API_PATH=/job/cloudrouter-build-rpms/lastSuccessfulBuild/api/json
BUILD_SERVER_URL=${BUILD_SERVER_PROTO}://${BUILD_SERVER_HOST}:${BUILD_SERVER_PORT}${BUILD_SERVER_API_PATH}
CURL_CMD="curl --insecure"

if [ ! -d ~/.crsigning ] ; then
	# First run, setup...
	echo "First run"
	mkdir ~/.crsigning
	${CURL_CMD} ${BUILD_SERVER_URL} | jq '.number' > ~/.crsigning/lastBuild
fi

# Compare last locally known build to last successful remote build
LAST_BUILD_LOCAL=`cat ~/.crsigning/lastBuild`
${CURL_CMD} ${BUILD_SERVER_URL} | jq '.number' > ~/.crsigning/lastBuild
LAST_BUILD_REMOTE=`cat ~/.crsigning/lastBuild`
if [ ${LAST_BUILD_REMOTE} -gt ${LAST_BUILD_LOCAL} ] ; then
	# New build available, download all the artifacts
	BUILD_URL=`${CURL_CMD} ${BUILD_SERVER_URL} | jq -r '.url'`
	${CURL_CMD} ${BUILD_SERVER_URL} | jq -r '.artifacts[]' | grep fileName | while read -r line; do
		FILE_NAME=`echo ${line} | cut -d '"' -f4`
		${CURL_CMD} "${BUILD_URL}/artifact/${FILE_NAME}" -o ${FILE_NAME}
	done
fi
