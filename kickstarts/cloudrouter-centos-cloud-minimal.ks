%include common/cloudrouter-base.ks
%include centos/cloudrouter-centos-base.ks
%include common/cloudrouter-cloud.ks.in
%include common/cloudrouter-cleanup.ks.in

%packages
%include common/base-package-list
%include common/cloud-package-list
%end
