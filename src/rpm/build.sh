#!/bin/sh
mkdir opendaylight-service
cd opendaylight-service
cp ../SOURCES/opendaylight.service .
cd ..
tar -czvf opendaylight-service.tar.gz opendaylight-service
cp opendaylight-service.tar.gz ~/rpmbuild/SOURCES/
rm -rf opendaylight-service*
pwd
cp SPECS/* ~/rpmbuild/SPECS/
cp SOURCES/* ~/rpmbuild/SOURCES/
rm -rf ~/rpmbuild/BUILD/
curl -o ~/rpmbuild/SOURCES/RPM-GPG-KEY-CLOUDROUTER https://cloudrouter.org/repo/RPM-GPG-KEY-CLOUDROUTER
rpmbuild -ba --clean ~/rpmbuild/SPECS/cloudrouter-1.0.spec
if [ ! -f ~/rpmbuild/SOURCES/distribution-karaf-0.2.2-Helium-SR2.tar.gz ]
then
	curl -o ~/rpmbuild/SOURCES/distribution-karaf-0.2.2-Helium-SR2.tar.gz https://nexus.opendaylight.org/content/groups/public/org/opendaylight/integration/distribution-karaf/0.2.2-Helium-SR2/distribution-karaf-0.2.2-Helium-SR2.tar.gz
fi
rpmbuild -ba --clean ~/rpmbuild/SPECS/opendaylight-helium.spec
