repo --name=cloudrouter --baseurl=https://repo.cloudrouter.org/fedora/2/$basearch/
%include cloudrouter-base.ks
%include cloudrouter-fedora-repo.ks

%packages
cloudrouter-release-fedora
cloudrouter-release-fedora-notes
%end
