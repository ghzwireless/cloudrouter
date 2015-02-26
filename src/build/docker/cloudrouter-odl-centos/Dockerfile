FROM cloudrouter/base-centos:latest
MAINTAINER "Arun Neelicattu" <abn@iix.net>

RUN yum -y install opendaylight
RUN yum clean all

# expose ports as listed at https://github.com/opendaylight/integration/blob/master/packaging/docker/README.md
EXPOSE 162 179 1088 1790 1830 2400 2550 2551 2552 4189 4342 5005 5666 6633 6640 6653 7800 8000 8080 8101 8181 8383 12001

ENV JAVA_HOME /usr/lib/jvm/java
WORKDIR /opt/opendaylight/opendaylight-helium
CMD ["./bin/karaf" , "server"]
