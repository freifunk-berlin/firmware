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

# compile
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
	$(eval IB_FILE := $(shell ls $(LEDE_DIR)/bin/targets/$(MAINTARGET)/$(SUBTARGET)/*-imagebuilder-*.tar.bz2))
	cd $(IB_BUILD_DIR); tar xf $(IB_FILE)
	# shorten dir name to prevent too long paths
	mv $(IB_BUILD_DIR)/$(shell basename $(IB_FILE) .tar.bz2) $(IB_BUILD_DIR)/imgbldr
	export PATH=$(PATH):$(TOOLCHAIN_PATH); \
	PACKAGES_PATH="$(FW_DIR)/packages"; \
	for PROFILE_ITER in $(PROFILES); do \
	  for PACKAGES_FILE in $(PACKAGES_LIST_DEFAULT); do \
	    PROFILE=$$PROFILE_ITER \
	    CUSTOM_POSTINST_PARAM=""; \
	    if [[ $$PROFILE =~ ":" ]]; then \
	      SUFFIX="$$(echo $$PROFILE | cut -d':' -f 2)"; \
	      PACKAGES_SUFFIXED="$${PACKAGES_FILE}_$${SUFFIX}"; \
	      if [[ -f "$$PACKAGES_PATH/$$PACKAGES_SUFFIXED.txt" ]]; then \
	        PACKAGES_FILE="$$PACKAGES_SUFFIXED"; \
	        PROFILE=$$(echo $$PROFILE | cut -d':' -f 1); \
	      fi; \
	    fi; \
	    if [[ -f "$$PACKAGES_PATH/$$PACKAGES_FILE.sh" ]]; then \
	      CUSTOM_POSTINST_PARAM="CUSTOM_POSTINST_SCRIPT=$$PACKAGES_PATH/$$PACKAGES_FILE.sh"; \
	    fi; \
	    PACKAGES_FILE_ABS="$$PACKAGES_PATH/$$PACKAGES_FILE.txt"; \
	    PACKAGES_LIST=$$(grep -v '^\#' $$PACKAGES_FILE_ABS | tr -t '\n' ' '); \
	    $(UMASK);\
	    echo -e "\n *** Building Kathleen image file for profile \"$${PROFILE}\" with packages list \"$${PACKAGES_FILE}\".\n"; \
	    $(MAKE) -C $(IB_BUILD_DIR)/imgbldr image PROFILE="$$PROFILE" PACKAGES="$$PACKAGES_LIST" BIN_DIR="$(IB_BUILD_DIR)/imgbldr/bin/$$PACKAGES_FILE" $$CUSTOM_POSTINST_PARAM || exit 1; \
	  done; \
	done
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
	# copy different firmwares (like vpn, minimal) including imagebuilder
	for DIR_ABS in $(IB_BUILD_DIR)/imgbldr/bin/*; do \
	  TARGET_DIR=$(FW_TARGET_DIR)/$$(basename $$DIR_ABS); \
	  rm -rf $$TARGET_DIR; \
	  mv $$DIR_ABS $$TARGET_DIR; \
	  cp $(FW_TARGET_DIR)/$$VERSION_FILE $$TARGET_DIR/; \
	  for FILE in $$TARGET_DIR/lede*; do \
	    [ -e "$$FILE" ] || continue; \
	    NEWNAME="$${FILE/lede-/kathleen-}"; \
	    NEWNAME="$${NEWNAME/ar71xx-generic-/}"; \
	    NEWNAME="$${NEWNAME/mpc85xx-generic-/}"; \
	    NEWNAME="$${NEWNAME/squashfs-/}"; \
	    mv "$$FILE" "$$NEWNAME"; \
	  done; \
	done;
	# copy imagebuilder, sdk and toolchain (if existing)
	# remove old versions
	rm -f $(FW_TARGET_DIR)/*.tar.bz2
	cp -a $(LEDE_DIR)/bin/targets/$(MAINTARGET)/$(SUBTARGET)/*{imagebuilder,sdk,toolchain}*.tar.bz2 $(FW_TARGET_DIR)/
	# copy packages
	PACKAGES_DIR="$(FW_TARGET_DIR)/packages"; \
	rm -rf $$PACKAGES_DIR; \
	cp -a $(LEDE_DIR)/bin/$(MAINTARGET)/$(SUBTARGET)/packages $$PACKAGES_DIR
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
