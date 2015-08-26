%include cloudrouter-fedora-cloud-full.ks

%packages
%include common/ami-package-list
%end

%post
rm -f /etc/shadow-
%end
