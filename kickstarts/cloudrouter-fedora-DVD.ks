%include common/cloudrouter-base-DVD.ks
%include fedora/cloudrouter-fedora-base.ks
%include fedora/cloudrouter-fedora-fix.ks.in

%packages
%include common/base-package-list
%include common/cloudrouter-full-package-list
%end
