repo --name=cloudrouter --baseurl=https://repo.cloudrouter.org/fedora/22/$basearch/
%include cloudrouter-base.ks
%include cloudrouter-fedora-repo.ks

%packages
cloudrouter-fedora-release
cloudrouter-fedora-release-notes
%end
