#!/bin/bash
CR_SIGNING_DIR=~/.crsigning
NOTIFICATION_EMAIL=djorm@iix.net
BUILD_NUMBER=`cat build.sig | head -n 4 | tail -n 1 | sed -e 's/\r//'` # Sed is to strip trailing 0d which messes up bash's evaluation of the variable

if gpg --no-default-keyring --keyring=signers.gpg --verify build.sig ; then
	for rpm in ${CR_SIGNING_DIR}/${BUILD_NUMBER}/*.rpm; do
       		./sign.sh $rpm
	done
	echo "Please deploy the artifacts on the appropriate repo." | mail -s "CloudRouter build ${BUILD_NUMBER} artifacts have been signed" ${NOTIFICATION_EMAIL}
else
	echo "FYI" | mail -s "CloudRouter build ${BUILD_NUMBER} artifacts were not signed because an invalid signature was provided" ${NOTIFICATION_EMAIL}
fi
