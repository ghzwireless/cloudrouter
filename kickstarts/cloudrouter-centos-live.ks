%include common/cloudrouter-base.ks
%include centos/cloudrouter-centos-base.ks
%include common/cloudrouter-live.ks.in
%include common/cloudrouter-cleanup.ks.in

%packages
@hardware-support --optional
%include cloudrouter-full-package-list
%end
