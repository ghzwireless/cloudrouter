%include cloudrouter-fedora-cloud-full.ks

# NOTE :: EC2 doesn't like when the bootloader is grub or grub2.
# Based on https://git.fedorahosted.org/cgit/spin-kickstarts.git/tree/fedora-cloud-base.ks?h=f22
# extlinux will be the bootloader
# CentOS - works with grub2 on amazon ec2
bootloader --timeout=1

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
