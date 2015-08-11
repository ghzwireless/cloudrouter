repo --name=cloudrouter --baseurl=https://repo.cloudrouter.org/centos/7/$basearch/
%include cloudrouter-base.ks

# including epel for cloud-init
repo --name=epel7 --baseurl=http://dl.fedoraproject.org/pub/epel/7/x86_64/

%packages
epel-release
cloudrouter-centos-release
cloudrouter-centos-release-notes
%end
