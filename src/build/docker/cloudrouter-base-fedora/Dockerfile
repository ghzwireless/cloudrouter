FROM fedora:20
MAINTAINER "Arun Neelicattu" <abn@iix.net>

RUN yum -y install \
    deltarpm \
    https://cloudrouter.org/repo/beta/x86_64/cloudrouter-release-1-1.noarch.rpm
RUN rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CLOUDROUTER
RUN yum -y clean all

ONBUILD RUN yum -y update && yum -y clean all
