# Copyright 2015 CloudRouter Project Authors.

PRODUCT     := CloudRouter
VERSION     := 1.0
OS          := fedora
OS_VERSION  := 20
OS_TREE     := http://dl.fedoraproject.org/pub/fedora/linux/releases/20/Fedora/x86_64/os/

ISO_PREFIX	:= $(PRODUCT)-$(VERSION)-$(OS)
ISO_NAME	:= $(ISO_PREFIX).iso

IMG_NAME	:= $(ISO_PREFIX).raw
IMG_MANIFEST:= $(ISO_PREFIX).manifest
TMP_NAME    := cloudrouter-virt-tmp
TMP_FILE    := /tmp/build-rpm-manifest.txt
TMP_KS    := ksflatten.txt


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

virt-img: 
	ksflatten -c cloudrouter-$(OS)-cloud.ks -o $(TMP_KS)
	sudo virt-install \
	--name=$(TMP_NAME) \
	--ram=2048 \
	--cpu=host --vcpus=2 \
	--os-type=linux \
	--initrd-inject=$(TMP_KS) \
	--extra-args="inst.ks=file:/$(TMP_KS) console=tty0 console=ttyS0,115200" \
	--disk $(IMG_NAME),size=6,format=raw \
	--serial pty \
	--location=$(OS_TREE) \
	--nographics \
	--noreboot 
	sudo virt-cat $(IMG_NAME) $(TMP_FILE) > $(IMG_MANIFEST)
	sudo xz --verbose --force $(IMG_NAME)
	
all: livecd virt-img

# Phony targets for cleanup and similar uses
#
# .PHONY: clean

clean:
	sudo rm -f *.iso *.raw *.xz $(TMP_KS) *.manifest
	sudo virsh destroy $(TMP_NAME) || true
	sudo virsh undefine $(TMP_NAME) || true
