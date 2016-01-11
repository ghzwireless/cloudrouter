# Copyright 2015 CloudRouter Project Authors.

PRODUCT         := CloudRouter
VERSION         := 3.0
OS              := fedora
OS_VERSION      := 23
OS_TREE         := http://dl.fedoraproject.org/pub/fedora/linux/releases/23/Server/x86_64/os/
PROFILE         := minimal

ISO_PREFIX	    := $(PRODUCT)-$(VERSION)-$(OS)-$(PROFILE)
ISO_NAME	    := $(ISO_PREFIX).iso
IMG_NAME        := $(ISO_PREFIX)
AMI_IMG_NAME    := $(PRODUCT)-$(VERSION)-$(OS)-ami
DOCKER_IMG_NAME := $(ISO_PREFIX)-docker

# This is a file from inside the built image and it is defined
# in the kickstart file as part of a post-build action.
TMP_FILE        := /tmp/build-rpm-manifest.txt

TMP_NAME        := cloudrouter-virt-tmp
TMP_KS          := ksflatten.txt

LOG_DIR         := $(shell mktemp -d)
TMP_LOG         := $(LOG_DIR)/$(TMP_NAME).log

MOCK_ENV        := cloudrouter-mock
MOCK_CFG        := $(OS)/cloudrouter-mock.cfg
MOCK_KS         := ks.cfg
MOCK_ARCH       := x86_64

VM_DISK_SIZE    := 6

# These need to match up with the values specified in /etc/libvirt/qemu.conf
VIRT_USER       := root
VIRT_GROUP      := root

all: livecd virt-img docker-img isobuild amibuild

# serial output will be logged to a /tmp file as jenkins runs without tty.
virt-img: KS_FILE=cloudrouter-$(OS)-cloud-$(PROFILE).ks
virt-img: $(IMG_NAME).raw.xz $(IMG_NAME).manifest $(IMG_NAME).vmdk

## the output .tar.xz can be used directly in a Dockerfile or used with docker import cmd
docker-img: KS_FILE=cloudrouter-$(OS)-docker.ks
docker-img: $(DOCKER_IMG_NAME).tar.xz Dockerfile

amibuild: KS_FILE=cloudrouter-$(OS)-ami.ks
amibuild: $(AMI_IMG_NAME).xz

# Args: BASE_DISTRO BASE_VERSION IMAGE_NAME
livecd: KS_FILE = cloudrouter-$(OS)-live.ks
livecd: $(TMP_KS)
	sudo livecd-creator \
	  --verbose \
	  --product="$(PRODUCT) $(VERSION)" \
	  --config=$(TMP_KS) \
	  --releasever="$(VERSION)" \
	  --fslabel="$(PRODUCT)-Live-$(VERSION)-$(OS)" \
	  --title "$(PRODUCT) Live $(VERSION) $(OS)" \
	  --cache=/var/cache/live

# isobuild target to generate DVD iso for CloudRouter
# this is based on mock and pungi
# Refer: http://fedoraproject.org/wiki/How_to_create_a_Fedora_install_ISO_for_testing
isobuild: KS_FILE=cloudrouter-$(OS)-DVD.ks
isobuild:
	$(eval VERSION=`echo $(VERSION) | cut -f1 -d"."`)
	ksflatten -c $(KS_FILE) -o $(MOCK_KS)
	sudo cp $(MOCK_CFG) /etc/mock/
	sudo mock -r $(MOCK_ENV) clean
	sudo mock -r $(MOCK_ENV) init
	sudo mock -r $(MOCK_ENV) --install pungi
	sudo mock -r $(MOCK_ENV) --install sed
	sudo mock -r $(MOCK_ENV) --copyin $(MOCK_KS) /
	sudo mock -r $(MOCK_ENV) --chroot "pungi --force \
		-G -C -B --isfinal --nosource --nodebuginfo \
		--name $(PRODUCT) --ver $(VERSION) -c /$(MOCK_KS)"
	sudo mock -r $(MOCK_ENV) --copyin \
		$(MOCK_KS) /$(VERSION)/$(MOCK_ARCH)/os/
	sudo mock -r $(MOCK_ENV) --chroot "sed -i \
		'/initrd.img/s/$$/ ks=cdrom:\/ks.cfg /' \
		/$(VERSION)/$(MOCK_ARCH)/os/isolinux/isolinux.cfg"
	sudo mock -r $(MOCK_ENV) --chroot "pungi --force \
		-I --isfinal --nosource --nodebuginfo \
		--name $(PRODUCT) --ver $(VERSION) -c /$(MOCK_KS)"
	sudo mock -r $(MOCK_ENV) --copyout /$(VERSION)/$(MOCK_ARCH)/iso/*DVD*.iso ./CloudRouter-$(OS)-$(VERSION)-DVD-$(MOCK_ARCH).iso

$(AMI_IMG_NAME).xz: $(AMI_IMG_NAME).raw.xz
	mv -f $< $@	

# The only actual dependency is the .raw file. Because the
#   xz compression changes the raw file, the manifest and
#   vmdk tasks must  be completed prior to compression of
#   the raw file.
%.raw.xz: %.raw
	xz --verbose --force --best -k $<

%.manifest: %.raw
	virt-cat --connect qemu:///system $^ $(TMP_FILE) > $@

%.vmdk: %.raw
	qemu-img convert -O vmdk $< $@

# virt-install takes longer when nested KVM is unsupported.
# Setting max wait time to 6h.
# serial output will be logged to a temp file as jenkins runs without tty.
%.raw: $(TMP_LOG) $(TMP_KS)
	virt-install \
	  --connect qemu:///system \
	  --name=$(TMP_NAME) \
	  --memory 2048 \
	  --cpu host \
	  --vcpus 2 \
	  --os-type=linux \
	  --initrd-inject=$(TMP_KS) \
	  --extra-args="inst.ks=file:/$(TMP_KS) console=tty0 console=ttyS0,115200" \
	  --disk $@,size=$(VM_DISK_SIZE),format=raw \
	  --location=$(OS_TREE) \
	  --network bridge=virbr0 \
	  --nographics \
	  --noreboot \
	  --wait 300 \
	  --serial file,path=$(TMP_LOG)

%.tar.xz: %.raw
	virt-tar-out -a $< / - | xz --best > $@

Dockerfile:
	echo "From scratch" > Dockerfile
	echo "MAINTAINER Jay Turner<jturner@iix.net>" >> Dockerfile
	echo "ADD $(ISO_PREFIX)-docker.tar.xz /" >> Dockerfile

$(TMP_KS):
	ksflatten -c $(KS_FILE) -o $@

$(TMP_LOG):
	chown -R $(VIRT_USER):$(VIRT_GROUP) $(LOG_DIR)
	touch $(TMP_LOG)
	chown $(VIRT_USER):$(VIRT_GROUP) $(TMP_LOG)

# Phony targets for cleanup and similar uses
#
# .PHONY: clean
clean:
	sudo rm -f *.log *.iso *.raw *.xz $(TMP_KS) *.manifest Dockerfile
	virsh --connect qemu:///system destroy $(TMP_NAME) || true
	virsh --connect qemu:///system undefine $(TMP_NAME) || true
