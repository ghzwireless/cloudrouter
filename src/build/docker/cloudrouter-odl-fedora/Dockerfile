FROM fedora:20
MAINTAINER "Arun Neelicattu" <aneelicattu@iix.net>

RUN yum -y update
RUN yum -y install deltarpm
RUN yum -y install https://cloudrouter.org/repo/beta/x86_64/cloudrouter-release-1-1.noarch.rpm
RUN rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CLOUDROUTER

# install additional packages
ADD assets/packages-full.list /tmp/packages-full.list
RUN yum -y install $(cat /tmp/packages-full.list)
RUN yum clean all

# expose ports as listed at https://github.com/opendaylight/integration/blob/master/packaging/docker/README.md
EXPOSE 162 179 1088 1790 1830 2400 2550 2551 2552 4189 4342 5005 5666 6633 6640 6653 7800 8000 8080 8101 8181 8383 12001

ENV JAVA_HOME /usr/lib/jvm/java-1.7.0
WORKDIR /opt/opendaylight/opendaylight-helium
CMD ["./bin/karaf" , "server"]
