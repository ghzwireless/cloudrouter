# CloudRouter Centos Cloud Full configuration is identical to the Minimal
#   configuration except that all of the CloudRouter RPM packages are
#   installed as part of the build.
%include cloudrouter-centos-cloud-minimal.ks

%packages
%include common/cloudrouter-full-package-list
%end
