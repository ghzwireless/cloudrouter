repo --name=fedora --mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=fedora-22&arch=$basearch
repo --name=cloudrouter --baseurl=https://repo.cloudrouter.org/repo/fedora/2/x86_64/

%packages 

kernel*
@system-tools
@core
grub2*

#include cloudrouter packages
cloudrouter-release-fedora
cloudrouter-release-fedora-notes

%end

