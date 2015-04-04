# CloudRouter Base kickstart
# Derrived from https://git.fedorahosted.org/cgit/spin-kickstarts.git/tree/fedora-live-base.ks?h=f20

lang en_US.UTF-8
keyboard us
timezone US/Eastern
auth --useshadow --enablemd5
selinux --enforcing
firewall --enabled --service=mdns
xconfig --startxonboot
part / --size 4096 --fstype ext4
services --enabled=NetworkManager --disabled=network,sshd

%include cloudrouter-repo.ks
%include cloudrouter-branding.ks

%packages
@guest-desktop-agents
@standard
@core
@input-methods
@hardware-support

# Explicitly specified here:
# <notting> walters: because otherwise dependency loops cause yum issues.
kernel

## cleanup
-smartmontools
-rsyslog
-mpage
-sox
-hplip
-hpijs
-numactl
-isdn4k-utils
-autofs
-coolkey

# scanning takes quite a bit of space :/
-xsane
-xsane-gimp
-sane-backends

# remmove plymouth
-plymouth
%end

%post
# work around for poor key import UI in PackageKit
rm -f /var/lib/rpm/__db*
find /etc/pki/rpm-gpg/ -maxdepth 1 -type f -name "RPM-GPG-KEY-*" \
    -exec rpm --import {} \;

echo "Packages within this build"
rpm -qa
# Note that running rpm recreates the rpm db files which aren't needed or wanted
rm -f /var/lib/rpm/__db*

# go ahead and pre-make the man -k cache (#455968)
/usr/bin/mandb

# save a little bit of space at least...
rm -f /boot/initramfs*
# make sure there aren't core files lying around
rm -f /core*
%end

%include cloudrouter-selinux-fix.ks
