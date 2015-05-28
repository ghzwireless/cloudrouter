%include cloudrouter-base.ks

# including epel for cloud-init
repo --name=epel7 --baseurl=http://dl.fedoraproject.org/pub/epel/7/x86_64/

%packages
epel-release
cloudrouter-release-centos
cloudrouter-release-centos-notes
cloud-init
%end

%post

# install rpm gpg keys
/usr/bin/rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-*

# Add cloud init - default user
/bin/cat >/etc/cloud/cloud.cfg.d/90_cloudrouter.cfg <<-EOF
system_info:
  default_user:
    name: cloudrouter
    gecos: CloudRouter User
    lock_passwd: true
    groups: [wheel, adm, systemd-journal]
    sudo: ["ALL=(ALL) NOPASSWD:ALL"]
    shell: /bin/bash

EOF

# Generate rpm manifest file
/usr/bin/rpm -qa > /tmp/build-rpm-manifest.txt

%end

