# including CloudRouter repo
repo --name=cloudrouter --baseurl=https://repo.cloudrouter.org/centos/7.2/$basearch/

# including CentOS 7 repos
repo --name=base --mirrorlist=http://mirrorlist.centos.org/?release=7&arch=$basearch&repo=os&infra=$infra
repo --name=updates --mirrorlist=http://mirrorlist.centos.org/?release=7&arch=$basearch&repo=updates&infra=$infra
repo --name=extras --mirrorlist=http://mirrorlist.centos.org/?release=7&arch=$basearch&repo=extras&infra=$infra
repo --name=centosplus --mirrorlist=http://mirrorlist.centos.org/?release=7&arch=$basearch&repo=centosplus&infra=$infra

# including EPEL 7
repo --name=epel7 --baseurl=http://dl.fedoraproject.org/pub/epel/7/x86_64/