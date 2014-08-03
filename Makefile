# default parameters
TARGET=ar71xx
OPENWRT_SRC=git://git.openwrt.org/openwrt.git
OPENWRT_COMMIT=65f9fd0dc881f5759a79dddee5d689e320626609
MAKE_ARGS="IGNORE_ERRORS=m"

# set variables
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

default: compile firmwares

# clone openwrt
$(OPENWRT_DIR):
	git clone $(OPENWRT_SRC) $(OPENWRT_DIR)

# update openwrt and checkout specified commit
update_openwrt: $(OPENWRT_DIR) clean_openwrt
	cd $(OPENWRT_DIR); git checkout --detach $(OPENWRT_COMMIT)

# clean up openwrt working copy
clean_openwrt: $(OPENWRT_DIR)
	cd $(OPENWRT_DIR); \
	  git clean -dff && git fetch && git reset --hard HEAD && \
	  rm -rf bin .config feeds.conf

# patches require updated openwrt working copy
$(OPENWRT_DIR)/patches: $(OPENWRT_DIR)
	ln -s $(FW_DIR)/patches $(OPENWRT_DIR)

# patch openwrt working copy
apply_patches: $(OPENWRT_DIR)/patches $(wildcard $(FW_DIR)/patches/*)
	$(MAKE) -C openwrt tools/quilt/install
	cd $(OPENWRT_DIR); $(OPENWRT_DIR)/staging_dir/host/bin/quilt push -a

# feeds
$(OPENWRT_DIR)/feeds.conf: $(OPENWRT_DIR) $(FW_DIR)/feeds.conf
	ln -s $(FW_DIR)/feeds.conf $(OPENWRT_DIR)/feeds.conf

# update feeds
update_feeds: $(OPENWRT_DIR)/feeds.conf
	+cd $(OPENWRT_DIR); \
	  ./scripts/feeds uninstall -a && \
	  ./scripts/feeds update && \
	  ./scripts/feeds install -a

# openwrt config
config: $(OPENWRT_DIR)
	cp $(TARGET_CONFIG) $(OPENWRT_DIR)/.config
	cd $(OPENWRT_DIR); make defconfig

# update config for new openwrt/feed versions
update_config: prepare
	cd $(OPENWRT_DIR); make oldconfig
	cp $(OPENWRT_DIR)/.config $(TARGET_CONFIG)

# prepare openwrt working copy
prepare: update_openwrt update_feeds config apply_patches

# compile
compile: prepare $(FW_DIR)/bin
	$(MAKE) -C openwrt $(MAKE_ARGS)

$(FW_DIR)/bin:
	rm -f $(FW_DIR)/bin
	ln -s $(OPENWRT_DIR)/bin $(FW_DIR)/bin

# fill firmwares-directory with:
#  * firmwares built with imagebuilder
#  * imagebuilder file
#  * packages directory
firmwares:
	rm -rf $(IB_BUILD_DIR)
	mkdir -p $(IB_BUILD_DIR)
	$(eval IB_FILE := $(shell ls $(FW_DIR)/bin/$(TARGET)/OpenWrt-ImageBuilder-$(TARGET)*.tar.bz2))
	$(eval IB_DIR := $(shell basename $(IB_FILE) .tar.bz2))
	cd $(IB_BUILD_DIR); tar xf $(IB_FILE)
	cd $(IB_BUILD_DIR)/$(IB_DIR); \
	  for PROFILE in $(PROFILES); do \
	    make image PROFILE="$$PROFILE" PACKAGES="$(PACKAGES)"; \
	  done
	mkdir -p $(FW_TARGET_DIR)
	rm -rf $(FW_TARGET_DIR)/$(TARGET)
	mv $(IB_BUILD_DIR)/$(IB_DIR)/bin/$(TARGET) $(FW_TARGET_DIR)
	cp $(IB_FILE) $(FW_TARGET_DIR)/$(TARGET)
	cp -a $(FW_DIR)/bin/$(TARGET)/packages $(FW_TARGET_DIR)/$(TARGET)
	rm -rf $(IB_BUILD_DIR)

clean: clean_openwrt

.PHONY: update_openwrt clean apply_patches update_feeds config update_config prepare compile firmwares

.NOTPARALLEL:
