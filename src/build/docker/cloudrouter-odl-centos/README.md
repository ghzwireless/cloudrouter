# CloudRouter (w/ OpenDaylight) Docker Container
CloudRouter container with [OpenDaylight](http://www.opendaylight.org/).

## Building
```sh
docker build --tag=cloudrouter/odl-centos .
```

## Running
Note that the following assumes that you to already have `cloudrouter/base-centos` built or available.

To run with default configuration:
```sh
docker run -d cloudrouter/odl-centos
```

## Stopping
```sh
# Stop container
docker stop ${CONTAINER_ID}
```
