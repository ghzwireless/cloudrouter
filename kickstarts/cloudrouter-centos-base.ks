repo --name=cloudrouter --baseurl=https://repo.cloudrouter.org/centos/$releasever/$basearch/
%include cloudrouter-base.ks

# including epel for cloud-init
repo --name=epel7 --baseurl=http://dl.fedoraproject.org/pub/epel/7/x86_64/

%packages
epel-release
cloudrouter-release-centos
cloudrouter-release-centos-notes
%end
