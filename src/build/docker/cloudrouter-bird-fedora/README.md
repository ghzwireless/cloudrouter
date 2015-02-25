# CloudRouter (w/ BIRD) Docker Container
CloudRouter container with [BIRD](http://bird.network.cz/).

## Building
```sh
docker build --tag=cloudrouter/bird-fedora .
```

## Running
Note that the following assumes that you to already have `cloudrouter/base-fedora` built or available.

To run with default configuration:
```sh
docker run -d cloudrouter/bird-fedora
```

To run with custom configuration, modify assets/conf/bird.conf and run the following:
```sh
BIRD_CONF_DIR=$(pwd)/assets/conf

# this is required if you are running under SELinux
chcon -Rt svirt_sandbox_file_t ${BIRD_CONF_DIR}

# run the container
docker run -v ${BIRD_CONF_DIR}:/etc/bird cloudrouter/bird-fedora
```

## Stopping
```sh
# Stop container
docker stop ${CONTAINER_ID}
```
