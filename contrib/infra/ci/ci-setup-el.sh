#!/usr/bin/env bash

# ensure we got everything we need to start building images
yum --assumeyes install \
    deltarpm wget curl gnupg python git genisoimage \
    qemu-kvm qemu-img virt-manager libvirt libvirt-python \
    libvirt-client net-tools libguestfs-tools

# import the fedora gpg key to be used for image verification
curl https://getfedora.org/static/fedora.gpg | gpg --import

# setup jenkins
wget -O /etc/yum.repos.d/jenkins.repo http://pkg.jenkins-ci.org/redhat/jenkins.repo
rpm --import http://pkg.jenkins-ci.org/redhat/jenkins-ci.org.key

yum --assumeyes install java jenkins firewalld

# configure firewall
systemctl start firewalld
firewall-cmd --permanent --zone=public --add-port=8080/tcp
firewall-cmd --permanent --zone=public --add-port=22/tcp
firewall-cmd --reload

# setup selfsigned ssl
# TODO: Make keystore generation more safe; remove default password
KEYSTORE_PASSWORD=${KEYSTORE_PASSWORD-jenkinscloudrouter}
KEYSTORE_FILE=var/lib/jenkins/keystore.jks
KEYTOOL_CMD="keytool -genkey -keyalg RSA -alias selfsigned -keystore ${KEYSTORE_FILE} -storepass ${KEYSTORE_PASSWORD} -dname \"cn=ci.cloudrouter.org\""
runuser -l jenkins -c ${KEYTOOL_CMD}
sed -i s/"JENKINS_PORT="/"JENKINS_PORT=-1"/ /etc/sysconfig/jenkins
echo "JENKINS_HTTPS_PORT=8443" >> /etc/sysconfig/jenkins
echo "JENKINS_HTTPS_KEYSTORE=${KEYSTORE_FILE}" >> /etc/sysconfig/jenkins
echo "JENKINS_HTTPS_KEYSTORE_PASSWORD=${KEYSTORE_PASSWORD}" >> /etc/sysconfig/jenkins

# fire up jenkins
chkconfig jenkins on
systemctl start jenkins

# ensure we are all up-to-date
yum --assumeyes update

# TODO: FIX
# PoC hack to allow jenkins to run as root for virsh magic
echo "jenkins   ALL=(ALL)       NOPASSWD: ALL" >> /etc/sudoers

# This is required to run sudo commands in jenkins workers
echo "Defaults:jenkins !requiretty" >> /etc/sudoers
