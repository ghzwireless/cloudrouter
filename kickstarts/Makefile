# Copyright 2015 CloudRouter Project Authors.

PRODUCT     := CloudRouter
VERSION     := 2.0
OS          := fedora
OS_VERSION  := 22
OS_TREE     := http://dl.fedoraproject.org/pub/fedora/linux/releases/22/Server/x86_64/os/

PROFILE     := minimal
ISO_PREFIX	:= $(PRODUCT)-$(VERSION)-$(OS)-$(PROFILE)
ISO_NAME	:= $(ISO_PREFIX).iso

IMG_NAME	:= $(ISO_PREFIX).raw
IMG_MANIFEST:= $(ISO_PREFIX).manifest
TMP_NAME    := cloudrouter-virt-tmp
TMP_FILE    := /tmp/build-rpm-manifest.txt
TMP_KS      := ksflatten.txt
LOG_DIR     := $(shell mktemp -d)
TMP_LOG     := $(LOG_DIR)/$(TMP_NAME).log
MOCK_ENV    := cloudrouter-mock
MOCK_CFG    := cloudrouter-mock.cfg
MOCK_ARCH   := x86_64
MOCK_KS     := cloudrouter-fedora-dvd-base.ks
AMI_IMG_NAME:= $(PRODUCT)-$(VERSION)-$(OS)-ami


# Args: BASE_DISTRO BASE_VERSION IMAGE_NAME
livecd: 
	ksflatten -c cloudrouter-$(OS)-live.ks -o $(TMP_KS)
	sudo livecd-creator \
	--verbose \
	--product="$(PRODUCT) $(VERSION)" \
	--config=$(TMP_KS) \
	--releasever="$(VERSION)" \
	--fslabel="$(PRODUCT)-Live-$(VERSION)-$(OS)" \
	--title "$(PRODUCT) Live $(VERSION) $(OS)" \
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
	--wait 300 \
	--serial file,path=$(TMP_LOG)
	virt-cat --connect qemu:///session $(IMG_NAME) $(TMP_FILE) > $(IMG_MANIFEST)
	xz --verbose --force $(IMG_NAME)

# virt-install takes longer when done on nested KVM
# setting max wait time to 4h
# the output .tar.xz can be used directly in a Dockerfile or used with docker import cmd
docker-img:
	ksflatten -c cloudrouter-$(OS)-docker.ks -o $(TMP_KS)
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
	--wait 300 \
	--serial file,path=$(TMP_LOG)
	virt-cat --connect qemu:///session $(IMG_NAME) $(TMP_FILE) > $(IMG_MANIFEST)
	virt-tar-out -a $(IMG_NAME) / - | xz --best > $(ISO_PREFIX)-docker.tar.xz
	echo "From scratch" > Dockerfile
	echo "MAINTAINER Jay Turner<jturner@iix.net>" >> Dockerfile
	echo "ADD $(ISO_PREFIX)-docker.tar.xz /" >> Dockerfile

# isobuild target to generate DVD iso for CloudRouter
# this is based on mock and pungi
# Refer: http://fedoraproject.org/wiki/How_to_create_a_Fedora_install_ISO_for_testing

isobuild:
	$(eval VERSION=`echo $(VERSION) | cut -f1 -d"."`)
	ksflatten -c cloudrouter-$(OS)-DVD.ks -o ks.cfg
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
		ks.cfg /$(VERSION)/$(MOCK_ARCH)/os/
	sudo mock -r $(MOCK_ENV) --chroot "sed -i \
		'/initrd.img/s/$$/ ks=cdrom:\/ks.cfg /' \
		/$(VERSION)/$(MOCK_ARCH)/os/isolinux/isolinux.cfg"
	sudo mock -r $(MOCK_ENV) --chroot "pungi --force \
		-I --isfinal --nosource --nodebuginfo \
		--name $(PRODUCT) --ver $(VERSION) -c /$(MOCK_KS)"
	sudo mock -r $(MOCK_ENV) --copyout /$(VERSION)/$(MOCK_ARCH)/iso/*DVD*.iso .


# virt-install takes longer when nested KVM is unsupported.
# Setting max wait time to 4h.
# serial output will be logged to a /tmp file as jenkins runs without tty.
# NOTE :: EC2 doesn't like when the bootloader is grub or grub2.
# Based on https://git.fedorahosted.org/cgit/spin-kickstarts.git/tree/fedora-cloud-base.ks?h=f22
# extlinux will be the bootloader
amibuild:
	ksflatten -c cloudrouter-$(OS)-ami.ks -o $(TMP_KS)
	sed -i '/^bootloader/s/$$/ --timeout=1 --extlinux /' $(TMP_KS)
	virt-install \
        --connect qemu:///session \
	--name=$(TMP_NAME) \
	--ram=2048 \
	--cpu=host --vcpus=2 \
	--os-type=linux \
	--initrd-inject=$(TMP_KS) \
	--extra-args="inst.ks=file:/$(TMP_KS) console=tty0 console=ttyS0,115200" \
	--disk $(AMI_IMG_NAME),size=6,format=raw \
	--location=$(OS_TREE) \
	--nographics \
	--noreboot \
	--wait 300 \
	--serial file,path=$(TMP_LOG)
	virt-cat --connect qemu:///session $(AMI_IMG_NAME) $(TMP_FILE) > $(IMG_MANIFEST)
	xz --verbose --force $(AMI_IMG_NAME)


all: livecd virt-img docker-img isobuild amibuild

# Phony targets for cleanup and similar uses
#
# .PHONY: clean

clean:
	sudo rm -f *.log *.iso *.raw *.xz $(TMP_KS) *.manifest Dockerfile
	virsh --connect qemu:///session destroy $(TMP_NAME) || true
	virsh --connect qemu:///session undefine $(TMP_NAME) || true
