# including CloudRouter repo
repo --name=cloudrouter --baseurl=https://repo.cloudrouter.org/repo/fedora/23/x86_64/

# including Fedora 22 repos
repo --name=fedora --mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=fedora-23&arch=$basearch
repo --name=updates --mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=updates-released-f23&arch=$basearch
