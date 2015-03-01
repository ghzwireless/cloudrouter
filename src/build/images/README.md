# CloudRouter Image Building Scripts

This directory contains scripts used to assist in generating CloudRouter image builds.

## Image Build Host Preparation

### Supported hosts
- RHEL 7+
- CentOS 7+
- Fedora 21+

### Required packages
In order to build images, the host machine should make available `virt-builder`.

For *RHEL/CentOS* before 7.1, we need the [libguestfs RHEL 7.1 preview repository](http://www.redhat.com/archives/virt-tools-list/2014-May/msg00053.html) to get a version of `libguestfs-tools` that contain `virt-builder`.
```sh
# This is required only for RHEL/CentOS 7.0.z
cat >/etc/yum.repos.d/libguestfs-RHEL-7.1-preview.repo <<EOF
[libguestfs-RHEL-7.1-preview]
name=libguestfs RHEL 7.1 preview - x86_64
baseurl=http://people.redhat.com/~rjones/libguestfs-RHEL-7.1-preview/
enabled=1
gpgcheck=0
EOF
```
Install the required packages:
```sh
# this works for Fedora 21+, RHEL/CentOS 7.1+ host
yum --assumeyes install \
    gnupg python qemu-kvm qemu-img virt-manager libvirt libvirt-client \
    libguestfs-tools
```
### `virt-builder` local repository
To use base images that are not available for consumption from the [libguestfs.org repository](http://libguestfs.org/download/builder/), we require a local repository to be made available to `virt-builder`. This process is documented [here](https://rwmj.wordpress.com/2014/09/11/creating-a-local-virt-builder-repository/).

This is also used by CloudRouter build servers to speed up build times on GCE instances as the updates to guests on GCE instances tend to be really slow.

#### Installation
The following snippet can be used as root to create a user repository.
```sh
# the user you want uploading images to this repo should have read/write access
REPO_USER=jenkins
REPO_DIR=$(echo ~${REPO_USER})/virt-builder/repo
INDEX_FILE=${REPO_DIR}/index

runuser -l ${REPO_USER} -s /usr/bin/bash -c "mkdir -p ${REPO_DIR}"
runuser -l ${REPO_USER} -s /usr/bin/bash -c"touch ${INDEX_FILE}"

cat > /etc/virt-builder/repos.d/local.conf << EOF
[${REPO_USER}]
uri=file://${INDEX_FILE}
proxy=off
EOF
```

#### Update latest images (GCE speed-up)
In order to update an image in the local repository, a helper script that updates the existing image or builds a new up-to-date image is provided as `host/virt-builder-update-local-repo`. This script generates the required meta-data for index file in the specified repository.

```sh
# Get jenkins user to update its local repository copy of centos-7.0
runuser \
    -l jenkins \
    -s /usr/bin/bash \
    -c 'virt-builder-update-local-rep --os centos --version 7.0 --repo jenkins --suffix latest'
```

This will add a new builder, if it does not already exist, or update the existing builder named `centos-7.0-latest` in the `jenkins` users local repository as configured during installation in `/etc/virt-builder/repos.d/local.conf`.

## Troubleshooting
### 'virt-builder' disables cache due to `Unix.ENOENT` error
When using the the packages provided from the [libguestfs RHEL 7.1 preview repository](http://www.redhat.com/archives/virt-tools-list/2014-May/msg00053.html), you might encounter issues with cache directory creation.
```
virt-builder: warning: cache /home/abn/.cache/virt-builder:
Unix.Unix_error(Unix.ENOENT, "mkdir", "/home/abn/.cache/virt-builder")
virt-builder: warning: disabling the cache
```

This can be worked around by creating the required directory path.

```sh
# do this for any user you intent to run virt-builder as
VIRT_BUILDER_USER=jenkins
runuser \
    -l ${VIRT_BUILDER_USER}
    -s /usr/bin/bash
    -c "mkdir -p ~${VIRT_BUILDER_USER}/.cache/virt-builder"
```

### SELinux preventing user from creating temporary guest
When running `virt-builder` as a non-root user under SELinux enabled environments, you might encounter AVC denials.

You can verify that SELinux is indeed the issue by temporarily setting it to be permissive.
```sh
setenforce 0
# this will succeed now
virt-builder centos 7.0 --output /tmp/test.img
setenfroce 1
```

```sh
$ grep 'qemu-kvm' /var/log/audit/audit.log

type=AVC msg=audit(1425102252.989:3986): avc:  denied  { write } for  pid=8849
comm="qemu-kvm" name="lib" dev="sda1" ino=30937
scontext=unconfined_u:system_r:svirt_tcg_t:s0:c317,c542
tcontext=system_u:object_r:virt_var_lib_t:s0 tclass=dir
```

You can work around with the help of `audit2allow` tool. For additional reference see [here](https://access.redhat.com/documentation/en-US/Red_Hat_Enterprise_Linux/6/html/Security-Enhanced_Linux/sect-Security-Enhanced_Linux-Fixing_Problems-Allowing_Access_audit2allow.html).
```sh
# install audit2allow
yum install policycoeutils-python

# generate policy module
qemu-kvm /var/log/audit/audit.log | audit2allow -M qemu-kvm

# once you verify what is generated, activate it
semodule -i qemu-kvm.pp
```
