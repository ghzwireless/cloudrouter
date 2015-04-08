# Copyright 2015 CloudRouter Project Authors.

OSV_VERSION := 0.19
OSV_TARBALL := v$(OSV_VERSION).tar.gz
OSV_DIR     := osv-$(OSV_VERSION)
OSV_SRC_URL := https://github.com/cloudius-systems/osv/archive/$(OSV_TARBALL)
OSV_REPO    := https://github.com/cloudius-systems/osv.git 

# help for escaping comma and space in calls
, := ,
space :=
space +=
$(space) := 
$(space) +=

# Args: NAME APPS DESC
build-appliance = OSV_HOME=$(OSV_DIR) \
			 APPLIANCE_NAME="$(1)" \
			 APPS_CSV="$(2)" \
			 APPLIANCE_DESC="$(3)" \
			 ./build-appliance.sh

all: opendaylight

# current release tarballs do not include submodules, until this happens we will
# not use source tarballs
#
#$(OSV_TARBALL):
#	wget -O $(OSV_TARBALL) $(OSV_SRC_URL)

$(OUTPUT_DIR):
	mkdir -p $(OUTPUT_DIR)

$(OSV_DIR): $(OUTPUT_DIR)
	# tar xf $(OSV_TARBALL)
	git clone \
		-b v${OSV_VERSION} \
		--single-branch \
		$(OSV_REPO) $(OSV_DIR)
	( cd $(OSV_DIR) && git submodule update --init --recursive )
	( cd $(OSV_DIR) \
		&& find ../ -maxdepth 1 -type f -name "*.patch" \
		-exec bash -c "patch -p1 < {}" \; )

opendaylight: $(OSV_DIR)
	$(call build-appliance,cloudrouter/opendaylight,opendaylight$(,)cloud-init$(,)monitoring-agent,OpenDaylight$( )on$( )OSv)

# Phony targets for cleanup and similar uses
#
# .PHONY: clean

clean:
	rm -rf $(OSV_DIR)
