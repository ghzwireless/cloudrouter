# Cloud Router Docker Container
Proof of concept docker container for Cloud Router and runs ODL.

## Building
```sh
# This command is what use used by the helper script cr-odl-build.sh
docker build --tag=cloudrouter/odl .
```

## Running
The helper script `cr-odl-run.sh` runs the container in the foreground with all known ports mapped `1:1`.

```sh
# Run the container in detached mode with random ports
docker run -d -P cloudrouter/odl

# Stop container
docker stop ${CONTAINER_ID}

# Open an interactive shell in the container
docker run -i cloudrouter/odl '/usr/bin/bash'
```
