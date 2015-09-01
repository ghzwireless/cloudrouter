%include cloudrouter-fedora-cloud-full.ks

%packages
%include common/ami-package-list
%end

%post
rm -f /etc/shadow-

#disable root login
/bin/passwd -d root
/bin/passwd -l root

# remove password authentication from ssh config
/bin/sed -i "s|PasswordAuthentication yes|PasswordAuthentication no|" /etc/ssh/sshd_config

%end
