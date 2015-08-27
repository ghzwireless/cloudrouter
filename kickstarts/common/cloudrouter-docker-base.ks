# This is a minimal Fedora install designed to serve as a Docker base image. 
#

cmdline
# bootloader installation and configuration with kernel parameters
# Parameters net.ifnames=0 biosdevname=0 are added to disable Consistent Network Device Naming
bootloader --location=none --append="net.ifnames=0 biosdevname=0"

timezone --isUtc --nontp Etc/UTC
rootpw --lock --iscrypted locked
user --name=none

keyboard us
zerombr
clearpart --all
part / --size 4000 --fstype ext4
network --bootproto=dhcp --device=link --activate --onboot=on
shutdown

%post 

# Generate rpm manifest file
/usr/bin/rpm -qa > /tmp/build-rpm-manifest.txt

# remove the user anaconda forces us to make
userdel -r none

# Disables the Consistent Network Device Naming Rule
# https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/7/html/Networking_Guide/sec-Disabling_Consistent_Network_Device_Naming.html
# NOTE: THE RULE NAME IS DIFFERENT FOR FEDORA!
# CentOS 7 rule name
ln -s /dev/null /etc/udev/rules.d/80-net-name-slot.rules
# Fedora rule name
ln -s /dev/null /etc/udev/rules.d/80-net-setup-link.rules

# simple eth0 config, again not hard-coded to the build hardware
cat > /etc/sysconfig/network-scripts/ifcfg-eth0 << EOF
DEVICE="eth0"
BOOTPROTO="dhcp"
ONBOOT="yes"
TYPE="Ethernet"
PERSISTENT_DHCLIENT="yes"
EOF

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
