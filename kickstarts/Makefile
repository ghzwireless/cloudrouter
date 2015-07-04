# Copyright 2015 CloudRouter Project Authors.

PRODUCT     := CloudRouter
VERSION     := 2.0
OS          := fedora
OS_VERSION  := 22
OS_TREE     := http://dl.fedoraproject.org/pub/fedora/linux/releases/22/Server/x86_64/os/

PROFILE   := minimal
ISO_PREFIX	:= $(PRODUCT)-$(VERSION)-$(OS)-$(PROFILE)
ISO_NAME	:= $(ISO_PREFIX).iso

IMG_NAME	:= $(ISO_PREFIX).raw
IMG_MANIFEST:= $(ISO_PREFIX).manifest
TMP_NAME    := cloudrouter-virt-tmp
TMP_FILE    := /tmp/build-rpm-manifest.txt
TMP_KS    := ksflatten.txt
LOG_DIR   := $(shell mktemp -d)
TMP_LOG   := $(LOG_DIR)/$(TMP_NAME).log


# Args: BASE_DISTRO BASE_VERSION IMAGE_NAME
livecd: 
	ksflatten -c cloudrouter-$(OS)-live.ks -o $(TMP_KS)
	sudo livecd-creator \
	--verbose \
	--product="$(PRODUCT) $(VERSION)" \
	--config=$(TMP_KS) \
	--releasever="$(OS_VERSION)" \
	--fslabel="$(PRODUCT)-$(VERSION)-$(OS)" \
	--title "$(PRODUCT) $(VERSION) $(OS)" \
	--cache=/var/cache/live

# virt-install takes longer when nested KVM is unsupported.
# Setting max wait time to 4h.
# serial output will be logged to a /tmp file as jenkins runs without tty.
virt-img: 
	ksflatten -c cloudrouter-$(OS)-cloud-$(PROFILE).ks -o $(TMP_KS)
	virt-install \
        --connect qemu:///session \
	--name=$(TMP_NAME) \
	--ram=2048 \
	--cpu=host --vcpus=2 \
	--os-type=linux \
	--initrd-inject=$(TMP_KS) \
	--extra-args="inst.ks=file:/$(TMP_KS) console=tty0 console=ttyS0,115200" \
	--disk $(IMG_NAME),size=6,format=raw \
	--location=$(OS_TREE) \
	--nographics \
	--noreboot \
	--wait 240 \
	--serial file,path=$(TMP_LOG)
	virt-cat --connect qemu:///session $(IMG_NAME) $(TMP_FILE) > $(IMG_MANIFEST)
	xz --verbose --force $(IMG_NAME)
	
all: livecd virt-img

# Phony targets for cleanup and similar uses
#
# .PHONY: clean

clean:
	sudo rm -f *.iso *.raw *.xz $(TMP_KS) *.manifest
	virsh --connect qemu:///session destroy $(TMP_NAME) || true
	virsh --connect qemu:///session undefine $(TMP_NAME) || true
