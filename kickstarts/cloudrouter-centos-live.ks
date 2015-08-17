%include common/cloudrouter-base.ks
%include centos/cloudrouter-centos-base.ks
%include common/cloudrouter-live.ks.in

%packages
%include common/base-package-list
%include common/live-package-list
%include common/cloudrouter-full-package-list
%end
