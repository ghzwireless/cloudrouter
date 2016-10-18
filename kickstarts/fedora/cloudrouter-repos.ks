# including CloudRouter repo
repo --name=cloudrouter --baseurl=https://repo.cloudrouter.org/repo/4/fedora/24/x86_64/

# including Fedora 23 repos
repo --name=fedora --mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=fedora-24&arch=x86_64
repo --name=updates --mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=updates-released-f24&arch=x86_64
