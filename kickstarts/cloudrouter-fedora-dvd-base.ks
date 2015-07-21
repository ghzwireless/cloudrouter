repo --name=fedora --mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=fedora-22&arch=$basearch

%packages 

kernel*
@system-tools
@core
grub2*

%end

