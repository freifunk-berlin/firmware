include config.mk

# get main- and subtarget name from TARGET
MAINTARGET=$(word 1, $(subst _, ,$(TARGET)))
SUBTARGET=$(word 2, $(subst _, ,$(TARGET)))

# set dir and file names
FW_DIR=$(shell pwd)
OPENWRT_DIR=$(FW_DIR)/openwrt
TARGET_CONFIG=$(FW_DIR)/configs/$(TARGET).config
IB_BUILD_DIR=$(FW_DIR)/imagebuilder_tmp
FW_TARGET_DIR=$(FW_DIR)/firmwares

# if any of the following files have been changed: clean up openwrt dir
DEPS=$(TARGET_CONFIG) feeds.conf patches $(wildcard patches/*)

# packages to include in the images
PACKAGES=$(shell grep -v '^\#' $(FW_DIR)/packages/minimal.txt | tr -t '\n' ' ')
# profiles to be built (router models)
PROFILES=$(shell cat $(FW_DIR)/profiles/$(TARGET).profiles)

default: firmwares

# clone openwrt
$(OPENWRT_DIR):
	git clone $(OPENWRT_SRC) $(OPENWRT_DIR)

# clean up openwrt working copy
openwrt-clean: stamp-clean-openwrt-cleaned .stamp-openwrt-cleaned
.stamp-openwrt-cleaned: config.mk | $(OPENWRT_DIR)
	cd $(OPENWRT_DIR); \
	  git clean -dff && git fetch && git reset --hard HEAD && \
	  rm -rf bin .config feeds.conf
	touch $@

# update openwrt and checkout specified commit
openwrt-update: stamp-clean-openwrt-updated .stamp-openwrt-updated
.stamp-openwrt-updated: .stamp-openwrt-cleaned
	cd $(OPENWRT_DIR); git checkout --detach $(OPENWRT_COMMIT)
	touch $@

# patches require updated openwrt working copy
$(OPENWRT_DIR)/patches: | .stamp-openwrt-updated
	ln -s $(FW_DIR)/patches $(OPENWRT_DIR)

# feeds
$(OPENWRT_DIR)/feeds.conf: .stamp-openwrt-updated
	cp $(FW_DIR)/feeds.conf $(OPENWRT_DIR)/feeds.conf

# update feeds
feeds-update: stamp-clean-feeds-updated .stamp-feeds-updated
.stamp-feeds-updated: $(OPENWRT_DIR)/feeds.conf
	+cd $(OPENWRT_DIR); \
	  ./scripts/feeds uninstall -a && \
	  ./scripts/feeds update && \
	  ./scripts/feeds install -a
	touch $@

# openwrt config
$(OPENWRT_DIR)/.config: .stamp-feeds-updated $(TARGET_CONFIG)
	cp $(TARGET_CONFIG) $(OPENWRT_DIR)/.config
	cd $(OPENWRT_DIR); make defconfig

# patch openwrt working copy
patch: stamp-clean-patched .stamp-patched
.stamp-patched: $(OPENWRT_DIR)/.config $(wildcard $(FW_DIR)/patches/*) | $(OPENWRT_DIR)/patches
	$(MAKE) -C openwrt tools/quilt/install
	cd $(OPENWRT_DIR); $(OPENWRT_DIR)/staging_dir/host/bin/quilt push -a
	touch $@

# prepare openwrt working copy
prepare: stamp-clean-prepared .stamp-prepared
.stamp-prepared: .stamp-patched
	touch $@

# compile
compile: stamp-clean-compiled .stamp-compiled
.stamp-compiled: .stamp-prepared
	$(MAKE) -C openwrt $(MAKE_ARGS)
	# the imagebuilder does not run in certain cases (ar71xx_mikrotik)
	$(MAKE) -C openwrt target/imagebuilder/{clean,compile}
	touch $@

# fill firmwares-directory with:
#  * firmwares built with imagebuilder
#  * imagebuilder file
#  * packages directory
firmwares: stamp-clean-firmwares .stamp-firmwares
.stamp-firmwares: .stamp-compiled
	rm -rf $(IB_BUILD_DIR)
	mkdir -p $(IB_BUILD_DIR)
	$(eval IB_FILE := $(shell ls $(OPENWRT_DIR)/bin/$(MAINTARGET)/OpenWrt-ImageBuilder-$(TARGET)*.tar.bz2))
	$(eval IB_DIR := $(shell basename $(IB_FILE) .tar.bz2))
	cd $(IB_BUILD_DIR); tar xf $(IB_FILE)
	cd $(IB_BUILD_DIR)/$(IB_DIR); \
	  for PROFILE in $(PROFILES); do \
	    make image PROFILE="$$PROFILE" PACKAGES="$(PACKAGES)"; \
	  done
	mkdir -p $(FW_TARGET_DIR)
	rm -rf $(FW_TARGET_DIR)/$(MAINTARGET)
	mv $(IB_BUILD_DIR)/$(IB_DIR)/bin/$(MAINTARGET) $(FW_TARGET_DIR)
	cp $(IB_FILE) $(FW_TARGET_DIR)/$(MAINTARGET)
	cp -a $(OPENWRT_DIR)/bin/$(MAINTARGET)/packages $(FW_TARGET_DIR)/$(MAINTARGET)
	rm -rf $(IB_BUILD_DIR)
	touch $@

stamp-clean-%:
	rm -f .stamp-$*

stamp-clean:
	rm -f .stamp-*

clean: stamp-clean .stamp-openwrt-cleaned

.PHONY: openwrt-clean openwrt-update patch feeds-update prepare compile firmwares stamp-clean clean
.NOTPARALLEL:
