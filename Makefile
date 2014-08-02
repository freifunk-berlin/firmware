# default parameters
TARGET=ar71xx
OPENWRT_SRC=git://git.openwrt.org/openwrt.git
OPENWRT_COMMIT=65f9fd0dc881f5759a79dddee5d689e320626609

# set variables
FW_DIR=$(shell pwd)
OPENWRT_DIR=$(FW_DIR)/openwrt
TARGET_CONFIG=$(FW_DIR)/configs/$(TARGET).config

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
	ln -s $(FW_DIR)/patches $(OPENWRT_DIR)/patches

# patch openwrt working copy
apply_patches: $(OPENWRT_DIR)/patches $(wildcard $(FW_DIR)/patches/*)
	+cd $(OPENWRT_DIR); quilt push -a

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
prepare: update_openwrt apply_patches update_feeds config

# compile
compile: prepare $(FW_DIR)/bin
	$(MAKE) -C openwrt

$(FW_DIR)/bin:
	rm -f $(FW_DIR)/bin
	ln -s $(OPENWRT_DIR)/bin $(FW_DIR)/bin

clean: clean_openwrt
	
.PHONY: update_openwrt clean apply_patches update_feeds config update_config prepare compile

.NOTPARALLEL:
