# Copyright 2015 CloudRouter Project Authors.

PRODUCT     = CloudRouter
VERSION     = 1.0
FEDORA_BASE = 20
IMAGE_NAME  = LiveCD
LIVE_KS     = cloudrouter-live.ks

ISO = $(PRODUCT)-$(VERSION)-$(IMAGE_NAME).iso

all: $(ISO)
	sudo livecd-creator \
	    --verbose \
	    --product="$(PRODUCT) $(VERSION)" \
	    --releasever="$(FEDORA_BASE)" \
	    --config=$(LIVE_KS) \
	    --fslabel="$(PRODUCT)-$(VERSION)-$(IMAGE_NAME)" \
	    --title "$(PRODUCT) $(VERSION) $(IMAGE_NAME)" \
	    --cache=/var/cache/live

# Phony targets for cleanup and similar uses
#
# .PHONY: clean

clean:
	sudo rm -f *.iso
