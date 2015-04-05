text
lang en_US.UTF-8
keyboard us
timezone US/Eastern

auth --useshadow --enablemd5
selinux --enforcing
rootpw --lock --iscrypted locked
user --name=none

firewall --enabled --service=mdns

bootloader --location=mbr --append="console=tty0 console=ttyS0,115200"
zerombr

clearpart --all --initlabel
part / --size 4096 --fstype ext4

network --bootproto=dhcp --device=link --activate --onboot=on
services --enabled=network,sshd,rsyslog

%include cloudrouter-repo.ks

%packages
@core

# explicit packages
kernel
firewalld

-plymouth
%end
