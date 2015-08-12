%include common/cloudrouter-base.ks

# including CloudRouter repo
repo --name=cloudrouter --baseurl=https://repo.cloudrouter.org/fedora/22/$basearch/

# including Fedora 22 repos
repo --name=fedora --mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=fedora-22&arch=$basearch
repo --name=updates --mirrorlist=http://mirrors.fedoraproject.org/mirrorlist?repo=updates-released-f22&arch=$basearch

%packages
cloudrouter-fedora-release
cloudrouter-fedora-release-notes
%end
