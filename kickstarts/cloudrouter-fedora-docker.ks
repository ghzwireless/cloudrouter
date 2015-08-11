%include cloudrouter-fedora-repo.ks
%include cloudrouter-repo.ks
%include cloudrouter-docker-base.ks

%packages --excludedocs --instLangs=en --nocore --nobase
cloudrouter-fedora-release
cloudrouter-fedora-release-notes
%end

%post
# install rpm gpg keys
/usr/bin/rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-*
%end
