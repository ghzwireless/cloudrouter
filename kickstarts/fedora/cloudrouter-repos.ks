# including CloudRouter repo
repo --name=cloudrouter --baseurl=https://repo.cloudrouter.org/repo/fedora/22/x86_64/

# including Fedora 22 repos
repo --name=fedora --mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=fedora-22&arch=$basearch
repo --name=updates --mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=updates-released-f22&arch=$basearch
