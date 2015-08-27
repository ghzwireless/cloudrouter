%include centos/cloudrouter-repos.ks
%include common/cloudrouter-docker-base.ks

%packages --excludedocs --instLangs=en --nocore --nobase
%include common/docker-package-list

cloudrouter-centos-release
cloudrouter-centos-release-notes

%end



%post
# install rpm gpg keys
/usr/bin/rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-*
%end
