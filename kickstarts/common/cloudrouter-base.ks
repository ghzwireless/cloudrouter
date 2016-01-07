# cloudrouter-base.ks
# base kick start file for all cloudrouter kickstart files
install
cmdline
lang en_US.UTF-8
keyboard --vckeymap=us --xlayouts='us'
timezone America/New_York --isUtc --nontp

# setup authentication for the system
auth --disableshadow --passalgo=sha512

# enable SELinux because that is the way we roll
selinux --enforcing

# disable root password
rootpw --lock --iscrypted locked

# disable user by default override when required
user --name=none

# enable firewall and default services
firewall --enabled --service=mdns,ssh

# bootloader installation and configuration with kernel parameters
# Parameters net.ifnames=0 biosdevname=0 are added to disable Consistent Network Device Naming
bootloader --location=mbr --append="console=ttyS0,115200 console=tty1 net.ifnames=0 biosdevname=0"

# configure and activate network (link) at boot time
network --bootproto=dhcp --device=link --activate --onboot=on

# configure services to run at default runlevel
services --enabled=network,sshd,rsyslog

# Configure the disk:
#   1. Clear and initialize any invalid partition tables found on disk
#   2. Clear all partitions
#   3. Create root partition
#      TODO: split out boot and swap?
zerombr
clearpart --all --initlabel
part / --size 4096 --fstype ext4 --grow

# Shutdown after image creation completed.
shutdown

%post

# Set SSH banner 
echo cloudrouter | /usr/bin/figlet > /etc/ssh/sshd_banner
/bin/sed -i "s|#Banner none|Banner /etc/ssh/sshd_banner|" /etc/ssh/sshd_config

# install rpm gpg keys
/usr/bin/rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-*

echo -n "Network fixes"
# initscripts don't like this file to be missing.
# and https://bugzilla.redhat.com/show_bug.cgi?id=1204612
cat > /etc/sysconfig/network << EOF
NETWORKING=yes
NOZEROCONF=yes
DEVTIMEOUT=10
EOF

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

# Enable IPV4 forwarding
echo "net.ipv4.ip_forward = 1" > /etc/sysctl.d/90-cloudrouter.conf
echo "net.ipv6.conf.all.forwarding = 1" >> /etc/sysctl.d/90-cloudrouter.conf
echo "net.ipv6.conf.default.forwarding = 1" >> /etc/sysctl.d/90-cloudrouter.conf
echo "net.ipv6.route.max_size = 50000" >> /etc/sysctl.d/90-cloudrouter.conf

# enable getty term for all builds
systemctl enable getty@tty1.service

%end
