%include common/cloudrouter-base.ks
%include fedora/cloudrouter-fedora-base.ks
%include common/cloudrouter-cloud.ks.in
%include common/cloudrouter-cleanup.ks.in
%include fedora/cloudrouter-fedora-fix.ks.in

%packages
# base OS packages
%include common/base-package-list
%include common/cloud-package-list
%end