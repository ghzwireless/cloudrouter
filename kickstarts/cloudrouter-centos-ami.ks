%include cloudrouter-centos-cloud-full.ks

%packages
%include centos/ami-package-list
%end

%post
rm -f /etc/shadow-
%end

