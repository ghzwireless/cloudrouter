# Copyright 2015 CloudRouter Project Authors.

PRODUCT     := CloudRouter
VERSION     := 1.0
FEDORA_BASE := 20
ISO_PREFIX	:= $(PRODUCT)-$(VERSION)
ISO_FEDORA	:= $(ISO_PREFIX)-Fedora.iso

# Args: BASE_DISTRO BASE_VERSION IMAGE_NAME
live-iso = sudo livecd-creator \
	--verbose \
	--product="$(PRODUCT) $(VERSION)" \
	--config=cloudrouter-$(1)-live.ks \
	--releasever="$(2)" \
	--fslabel="$(PRODUCT)-$(VERSION)-$(3)" \
	--title "$(PRODUCT) $(VERSION) $(3)" \
	--cache=/var/cache/live

$(ISO_FEDORA):
	$(call live-iso,fedora,$(FEDORA_BASE),Fedora)

fedora-live: $(ISO_FEDORA)

all: fedora-live

# Phony targets for cleanup and similar uses
#
# .PHONY: clean

clean:
	sudo rm -f *.iso
