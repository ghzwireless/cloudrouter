# Copyright 2015 CloudRouter Project Authors.

PRODUCT         := CloudRouter
VERSION         := 4.0
OS              := fedora
OS_VERSION      := 24
OS_TREE         := http://dl.fedoraproject.org/pub/fedora/linux/releases/24/Server/x86_64/os/
PROFILE         := minimal

ISO_PREFIX      := $(PRODUCT)-$(VERSION)-$(OS)-$(PROFILE)
ISO_NAME        := $(ISO_PREFIX).iso
IMG_NAME        := cloudrouter-$(OS)-cloud-$(PROFILE)

MOCK_ENV        := cloudrouter-mock
MOCK_CFG        := $(OS)/cloudrouter-mock.cfg
MOCK_KS         := ks.cfg
MOCK_ARCH       := x86_64

THREADS         := 4

VM_DISK_SIZE    := 10

# Specifying an HTTP proxy speeds up repeated virtual image builds considerably.
# To use this feature, specify the PROXY_URL from the command line like this:
#   # make virt-img PROXY_URL=http://127.0.0.1:3128
ifdef PROXY_URL
PROXY_VIRT_ARGS := inst.proxy=$(PROXY_URL)
PROXY_LIVE_ARGS := HTTP_PROXY=$(PROXY_URL)
else
PROXY_VIRT_ARGS :=
PROXY_LIVE_ARGS :=
endif

all: livecd virt-img docker-img isobuild amibuild

# serial output will be logged to a /tmp file as jenkins runs without tty.
virt-img: $(IMG_NAME).manifest $(IMG_NAME).vmdk.xz $(IMG_NAME).raw.xz

## the output .tar.xz can be used directly in a Dockerfile or used with docker import cmd
docker-img: cloudrouter-$(OS)-docker.tar.xz Dockerfile

amibuild: cloudrouter-$(OS)-ami.xz

# Args: BASE_DISTRO BASE_VERSION IMAGE_NAME
livecd: cloudrouter-$(OS)-live.ks.cfg
	sudo $(PROXY_LIVE_ARGS) \
	  livecd-creator \
	  --verbose \
	  --product="$(PRODUCT) $(VERSION)" \
	  --config=$< \
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

cloudrouter-$(OS)-ami.xz: cloudrouter-$(OS)-ami.raw.xz
	mv -f $< $@	

# The only actual dependency is the .raw file. Because the
#   xz compression changes the raw file, the manifest and
#   vmdk tasks must  be completed prior to compression of
#   the raw file.
%.raw.xz: %.raw
	xz --threads=$(THREADS) --verbose --force --best -k $<

# /tmp/build-rpm-manifest.txt is a file from inside the built image and
# it is defined in the kickstart file as part of a post-build action.
%.manifest: %.raw
	virt-cat $^ /tmp/build-rpm-manifest.txt > $@

%.vmdk.xz: %.vmdk
	xz --threads=$(THREADS) --verbose --force --best -k $<

%.vmdk: %.raw
	qemu-img convert -O vmdk $< $@

# virt-install takes longer when nested KVM is unsupported.
# Setting max wait time to 6h.
# serial output will be logged to a temp file as jenkins runs without tty.
%.raw: %.ks.cfg
	virsh destroy $(basename $@) || true
	virsh undefine $(basename $@) || true
	virt-install \
	  --name=$(basename $@) \
	  --memory 2048 \
	  --cpu host \
	  --vcpus 2 \
	  --accelerate \
	  --os-type=linux \
	  --initrd-inject=$< \
	  --extra-args="inst.ks=file:/$< $(PROXY_VIRT_ARGS) console=tty0 console=ttyS0,115200" \
	  --disk $@,size=$(VM_DISK_SIZE),format=raw \
	  --location=$(OS_TREE) \
	  --network bridge=virbr0 \
	  --nographics \
	  --noreboot \
	  --wait 300 \
	  --serial file,path=/tmp/$(basename $@).log
	mv /tmp/$(basename $@).log ./

%.tar.xz: %.raw
	virt-tar-out -a $< / - | xz --best > $@

Dockerfile:
	echo "From scratch" > Dockerfile
	echo "MAINTAINER Jay Turner<jturner@console.to>" >> Dockerfile
	echo "ADD cloudrouter-$(OS)-docker.tar.xz /" >> Dockerfile

%.ks.cfg: %.ks
	ksflatten -c $< -o $@
ifdef PROXY_URL
	sed -i 's|^repo --.*|& --proxy=$(PROXY_URL)|' $@
endif

# Phony targets for cleanup and similar uses
#
# .PHONY: clean
clean:
	rm -f *.log *.iso *.raw *.xz *.vmdk *.manifest *.ks.cfg Dockerfile /tmp/$(PRODUCT)*.log
