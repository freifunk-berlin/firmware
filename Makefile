include config.mk

# get main- and subtarget name from TARGET
MAINTARGET=$(word 1, $(subst _, ,$(TARGET)))
SUBTARGET=$(word 2, $(subst _, ,$(TARGET)))

GIT_REPO=git config --get remote.origin.url
GIT_BRANCH=git symbolic-ref HEAD | sed -e 's,.*/\(.*\),\1,'
REVISION=git describe --always

# set dir and file names
FW_DIR=$(shell pwd)
LEDE_DIR=$(FW_DIR)/lede
TARGET_CONFIG=$(FW_DIR)/configs/$(TARGET).config $(FW_DIR)/configs/common.config
IB_BUILD_DIR=$(FW_DIR)/imgbldr_tmp
FW_TARGET_DIR=$(FW_DIR)/firmwares/$(TARGET)
UMASK=umask 022

# if any of the following files have been changed: clean up lede dir
DEPS=$(TARGET_CONFIG) feeds.conf patches $(wildcard patches/*)

# profiles to be built (router models)
PROFILES=$(shell cat $(FW_DIR)/profiles/$(TARGET).profiles)

FW_REVISION=$(shell $(REVISION))

default: firmwares

# clone lede
$(LEDE_DIR):
	git clone $(LEDE_SRC) $(LEDE_DIR)

# clean up lede working copy
lede-clean: stamp-clean-lede-cleaned .stamp-lede-cleaned
.stamp-lede-cleaned: config.mk | $(LEDE_DIR)
	cd $(LEDE_DIR); \
	  ./scripts/feeds clean && \
	  git clean -dff && git fetch && git reset --hard HEAD && \
	  rm -rf bin .config feeds.conf build_dir/target-* logs/
	touch $@

# update lede and checkout specified commit
lede-update: stamp-clean-lede-updated .stamp-lede-updated
.stamp-lede-updated: .stamp-lede-cleaned
	cd $(LEDE_DIR); git checkout --detach $(LEDE_COMMIT)
	touch $@

# patches require updated lede working copy
$(LEDE_DIR)/patches: | .stamp-lede-updated
	ln -s $(FW_DIR)/patches $(LEDE_DIR)

# feeds
$(LEDE_DIR)/feeds.conf: .stamp-lede-updated
	cp $(FW_DIR)/feeds.conf $(LEDE_DIR)/feeds.conf

# update feeds
feeds-update: stamp-clean-feeds-updated .stamp-feeds-updated
.stamp-feeds-updated: $(LEDE_DIR)/feeds.conf
	+cd $(LEDE_DIR); \
	  ./scripts/feeds uninstall -a && \
	  ./scripts/feeds update && \
	  ./scripts/feeds install -a
	touch $@

# prepare patch
pre-patch: stamp-clean-pre-patch .stamp-pre-patch
.stamp-pre-patch: .stamp-feeds-updated $(wildcard $(FW_DIR)/patches/*) | $(LEDE_DIR)/patches
	touch $@

# patch lede working copy
patch: stamp-clean-patched .stamp-patched
.stamp-patched: .stamp-pre-patch
	cd $(LEDE_DIR); quilt push -a
	touch $@

.stamp-build_rev: .FORCE
ifneq (,$(wildcard .stamp-build_rev))
ifneq ($(shell cat .stamp-build_rev),$(FW_REVISION))
	echo $(FW_REVISION) | diff >/dev/null -q $@ - || echo -n $(FW_REVISION) >$@
endif
else
	echo -n $(FW_REVISION) >$@
endif

# share download dir
$(FW_DIR)/dl:
	mkdir $(FW_DIR)/dl
$(LEDE_DIR)/dl: $(FW_DIR)/dl
	ln -s $(FW_DIR)/dl $(LEDE_DIR)/dl

# lede config
$(LEDE_DIR)/.config: .stamp-feeds-updated $(TARGET_CONFIG) .stamp-build_rev $(LEDE_DIR)/dl
	cat $(TARGET_CONFIG) >$(LEDE_DIR)/.config
	sed -i "/^CONFIG_VERSION_NUMBER=/ s/\"$$/\+$(FW_REVISION)\"/" $(LEDE_DIR)/.config
	$(UMASK); \
	  $(MAKE) -C $(LEDE_DIR) defconfig

# prepare lede working copy
prepare: stamp-clean-prepared .stamp-prepared
.stamp-prepared: .stamp-patched $(LEDE_DIR)/.config
	sed -i 's,^# REVISION:=.*,REVISION:=$(FW_REVISION),g' $(LEDE_DIR)/include/version.mk
	touch $@

# compile lede
compile: stamp-clean-compiled .stamp-compiled
.stamp-compiled: .stamp-prepared
	$(UMASK); \
	  $(MAKE) -C $(LEDE_DIR) $(MAKE_ARGS)
	touch $@

# fill firmwares-directory with:
#  * firmwares built with imagebuilder
#  * imagebuilder file
#  * packages directory
firmwares: stamp-clean-firmwares .stamp-firmwares
.stamp-firmwares: .stamp-compiled
	rm -rf $(IB_BUILD_DIR)
	mkdir -p $(IB_BUILD_DIR)
	$(eval TOOLCHAIN_PATH := $(shell printf "%s:" $(LEDE_DIR)/staging_dir/toolchain-*/bin))
	$(eval IB_FILE := $(shell ls -tr $(LEDE_DIR)/bin/targets/$(MAINTARGET)/$(SUBTARGET)/*-imagebuilder-*.tar.xz | tail -n1))
	#mv $(IB_BUILD_DIR)/$(shell basename $(IB_FILE) .tar.bz2) $(IB_BUILD_DIR)/imgbldr
	mkdir -p $(FW_TARGET_DIR)
	# Create version info file
	GIT_BRANCH_ESC=$(shell $(GIT_BRANCH) | tr '/' '_'); \
	VERSION_FILE=$(FW_TARGET_DIR)/VERSION.txt; \
	echo "https://github.com/freifunk-berlin/firmware" > $$VERSION_FILE; \
	echo "https://wiki.freifunk.net/Berlin:Firmware" >> $$VERSION_FILE; \
	echo "Firmware: git branch \"$$GIT_BRANCH_ESC\", revision $(FW_REVISION)" >> $$VERSION_FILE; \
	# add lede revision with data from config.mk \
	LEDE_REVISION=`cd $(LEDE_DIR); $(REVISION)`; \
	echo "OpenWRT: repository from $(LEDE_SRC), git branch \"$(LEDE_COMMIT)\", revision $$LEDE_REVISION" >> $$VERSION_FILE; \
	# add feed revisions \
	for FEED in `cd $(LEDE_DIR); ./scripts/feeds list -n`; do \
	  FEED_DIR=$(addprefix $(LEDE_DIR)/feeds/,$$FEED); \
	  FEED_GIT_REPO=`cd $$FEED_DIR; $(GIT_REPO)`; \
	  FEED_GIT_BRANCH_ESC=`cd $$FEED_DIR; $(GIT_BRANCH) | tr '/' '_'`; \
	  FEED_REVISION=`cd $$FEED_DIR; $(REVISION)`; \
	  echo "Feed $$FEED: repository from $$FEED_GIT_REPO, git branch \"$$FEED_GIT_BRANCH_ESC\", revision $$FEED_REVISION" >> $$VERSION_FILE; \
	done
	./assemble_firmware.sh -p "$(PROFILES)" -i $(IB_FILE) -t $(FW_TARGET_DIR) -u "$(PACKAGES_LIST_DEFAULT)"
	# copy imagebuilder, sdk and toolchain (if existing)
	cp -a $(LEDE_DIR)/bin/targets/$(MAINTARGET)/$(SUBTARGET)/*{imagebuilder,sdk}*.tar.xz $(FW_TARGET_DIR)/
	cp -a $(LEDE_DIR)/bin/targets/$(MAINTARGET)/$(SUBTARGET)/*toolchain*.tar.bz2 $(FW_TARGET_DIR)/
	mkdir -p $(FW_TARGET_DIR)/packages/targets/$(MAINTARGET)/$(SUBTARGET)/packages
	# copy packages
	cp -a $(LEDE_DIR)/bin/targets/$(MAINTARGET)/$(SUBTARGET)/packages/* $(FW_TARGET_DIR)/packages/targets/$(MAINTARGET)/$(SUBTARGET)/packages/
	# e.g. packages/packages/mips_34k the doublicated packages is correct!
	cp -a $(LEDE_DIR)/bin/packages $(FW_TARGET_DIR)/packages/
	rm -rf $(IB_BUILD_DIR)
	touch $@

stamp-clean-%:
	rm -f .stamp-$*

stamp-clean:
	rm -f .stamp-*

clean: stamp-clean .stamp-lede-cleaned

.PHONY: lede-clean lede-update patch feeds-update prepare compile firmwares stamp-clean clean
.NOTPARALLEL:
.FORCE:
