# default parameters
TARGET=ar71xx
OPENWRT_SRC=git://git.openwrt.org/openwrt.git
OPENWRT_COMMIT=65f9fd0dc881f5759a79dddee5d689e320626609
MAKE_ARGS="IGNORE_ERRORS=m"

# set variables
FW_DIR=$(shell pwd)
OPENWRT_DIR=$(FW_DIR)/openwrt
TARGET_CONFIG=$(FW_DIR)/configs/$(TARGET).config
TARGET_IB=$(FW_DIR)/imagebuilder/$(TARGET)

# packages to include in the images
PACKAGES=$(shell grep -v '^\#' $(FW_DIR)/packages/minimal.txt | tr -t '\n' ' ')
# profiles to be built (router models)
PROFILES=$(shell cat $(FW_DIR)/profiles/$(TARGET).profiles)

default: compile

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

# images
images:
	mkdir -p $(TARGET_IB)
	$(eval IB_FILE := $(shell ls $(FW_DIR)/bin/$(TARGET)/OpenWrt-ImageBuilder-$(TARGET)*.tar.bz2))
	cd $(TARGET_IB); tar xf $(IB_FILE)
	cd $(TARGET_IB)/$(shell basename $(IB_FILE) .tar.bz2); \
	  for PROFILE in "$(PROFILES)"; do \
	    make image PROFILE="$(PROFILE)" PACKAGES="$(PACKAGES)"; \
	  done

clean: clean_openwrt
	
.PHONY: update_openwrt clean apply_patches update_feeds config update_config prepare compile images

.NOTPARALLEL:
