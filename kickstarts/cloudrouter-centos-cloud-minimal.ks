# Minor differences exist between the base kickstart for CentOS and Fedora
#   that have yet to be resolved.
%include common/cloudrouter-base.ks

%include centos/cloudrouter-centos-base.ks
%include common/cloudrouter-cloud.ks.in
%include common/cloudrouter-cleanup.ks.in
