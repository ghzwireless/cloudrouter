# This is a minimal Fedora install designed to serve as a Docker base image. 
#

cmdline
bootloader --disabled
timezone --isUtc --nontp Etc/UTC
rootpw --lock --iscrypted locked
user --name=none

keyboard us
zerombr
clearpart --all
part / --size 4000 --fstype ext4
network --bootproto=dhcp --device=link --activate --onboot=on
shutdown

%packages --excludedocs --instLangs=en --nocore --nobase
@core --nodefaults
bash
rootfiles
vim-minimal
dnf
dnf-yum  
-kernel

%end

%post 

# Generate rpm manifest file
/usr/bin/rpm -qa > /tmp/build-rpm-manifest.txt

# remove the user anaconda forces us to make
userdel -r none

LANG="en_US"
echo "%_install_lang $LANG" > /etc/rpm/macros.image-language-conf

awk '(NF==0&&!done){print "override_install_langs='$LANG'\ntsflags=nodocs";done=1}{print}' \
    < /etc/yum.conf > /etc/yum.conf.new
mv /etc/yum.conf.new /etc/yum.conf

rm -f /usr/lib/locale/locale-archive

#Setup locale properly
localedef -v -c -i en_US -f UTF-8 en_US.UTF-8

rm -rf /var/cache/yum/*
rm -f /tmp/ks-script*

#Make it easier for systemd to run in Docker container
cp /usr/lib/systemd/system/dbus.service /etc/systemd/system/
sed -i 's/OOMScoreAdjust=-900//' /etc/systemd/system/dbus.service

#Mask mount units and getty service so that we don't get login prompt
systemctl mask systemd-remount-fs.service dev-hugepages.mount sys-fs-fuse-connections.mount systemd-logind.service getty.target console-getty.service

rm -f /etc/machine-id

%end
