# cloudrouter-base.ks
# base kick start file for all cloudrouter kickstart files
install
text
lang en_US.UTF-8
keyboard --vckeymap=us --xlayouts='us'
timezone America/New_York --isUtc --nontp

# setup authentication for the system
auth --useshadow --passalgo=sha512

# enable SELinux because that is the way we roll
selinux --enforcing

# Intentionally leaving out setting rootpw
# we will prompt for the user to set this by default.
#rootpw --lock --iscrypted locked

# disable user by default override when required
user --name=none

# enable firewall and default services
firewall --enabled --service=mdns,ssh

# bootloader installation and configuration with kernel parameters
bootloader --location=mbr 

# clear and initialize any invalid partition tables found on disk
zerombr

# clear all partitions
clearpart --all --initlabel

# autopart
autopart

# configure and activate network (link) at boot time
network --bootproto=dhcp --device=link --activate --onboot=on

# configure services to run at default runlevel
services --enabled=network,sshd,rsyslog

#reboot
reboot

%post
# Set SSH banner 
echo cloudrouter | /usr/bin/figlet > /etc/ssh/sshd_banner
/bin/sed -i "s|#Banner none|Banner /etc/ssh/sshd_banner|" /etc/ssh/sshd_config

# install rpm gpg keys
/usr/bin/rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-*

%end