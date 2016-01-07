%include fedora/cloudrouter-repos.ks
%include common/cloudrouter-docker-base.ks

%packages --excludedocs --instLangs=en
%include common/docker-package-list

cloudrouter-fedora-release
cloudrouter-fedora-release-notes
dnf
dnf-yum
%end

%post
# install rpm gpg keys
/usr/bin/rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-*
%end
