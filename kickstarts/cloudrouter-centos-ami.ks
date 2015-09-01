%include cloudrouter-centos-cloud-full.ks

%packages
%include centos/ami-package-list
%end

%post
rm -f /etc/shadow-

#disable root login
/bin/passwd -d root
/bin/passwd -l root

# remove password authentication from ssh config
/bin/sed -i "s|PasswordAuthentication yes|PasswordAuthentication no|" /etc/ssh/sshd_config

%end

