# including CloudRouter repo
repo --name=cloudrouter --baseurl=https://repo.cloudrouter.org/repo/3/centos/7/x86_64/

# including CentOS 7 repos
repo --name=base --mirrorlist=http://mirrorlist.centos.org/?release=7&arch=x86_64&repo=os&infra=$infra
repo --name=updates --mirrorlist=http://mirrorlist.centos.org/?release=7&arch=x86_64&repo=updates&infra=$infra
repo --name=extras --mirrorlist=http://mirrorlist.centos.org/?release=7&arch=x86_64&repo=extras&infra=$infra
repo --name=centosplus --mirrorlist=http://mirrorlist.centos.org/?release=7&arch=x86_64&repo=centosplus&infra=$infra

# including EPEL 7
repo --name=epel7 --baseurl=http://dl.fedoraproject.org/pub/epel/7/x86_64/

