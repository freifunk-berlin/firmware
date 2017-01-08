include config.mk

# get main- and subtarget name from TARGET
MAINTARGET=$(word 1, $(subst -, ,$(TARGET)))
SUBTARGET=$(word 2, $(subst -, ,$(TARGET)))

GIT_REPO=git config --get remote.origin.url
GIT_BRANCH=git symbolic-ref HEAD | sed -e 's,.*/\(.*\),\1,'
REVISION=git describe --always

# set dir and file names
FW_DIR=$(shell pwd)
LEDE_DIR=$(FW_DIR)/lede
TARGET_CONFIG=$(FW_DIR)/configs/common.config $(FW_DIR)/configs/$(MAINTARGET)-$(SUBTARGET).config
FW_TARGET_DIR=$(FW_DIR)/firmwares/$(MAINTARGET)-$(SUBTARGET)
VERSION_FILE=$(FW_TARGET_DIR)/VERSION.txt
UMASK=umask 022

# if any of the following files have been changed: clean up lede dir
DEPS=$(TARGET_CONFIG) feeds.conf patches $(wildcard patches/*)

# profiles to be built (router models)
PROFILES=$(shell cat $(FW_DIR)/profiles/$(MAINTARGET)-$(SUBTARGET).profiles)

FW_REVISION=$(shell $(REVISION))

default: firmwares

# clone lede
$(LEDE_DIR):
	git clone $(LEDE_SRC) $(LEDE_DIR)

# clean up lede working copy
lede-clean: stamp-clean-lede-cleaned .stamp-lede-cleaned
.stamp-lede-cleaned: config.mk | $(LEDE_DIR) lede-clean-bin
	cd $(LEDE_DIR); \
	  ./scripts/feeds clean && \
	  git clean -dff && git fetch && git reset --hard HEAD && \
	  rm -rf .config feeds.conf build_dir/target-* logs/
	touch $@

lede-clean-bin:
	rm -rf $(LEDE_DIR)/bin

# update lede and checkout specified commit
lede-update: stamp-clean-lede-updated .stamp-lede-updated
.stamp-lede-updated: .stamp-lede-cleaned
	cd $(LEDE_DIR); git checkout --detach $(LEDE_COMMIT)
	touch $@

# patches require updated lede working copy
$(LEDE_DIR)/patches: | .stamp-lede-updated
	ln -s $(FW_DIR)/patches $@

# feeds
$(LEDE_DIR)/feeds.conf: .stamp-lede-updated feeds.conf
	cp $(FW_DIR)/feeds.conf $@

# update feeds
feeds-update: stamp-clean-feeds-updated .stamp-feeds-updated
.stamp-feeds-updated: $(LEDE_DIR)/feeds.conf unpatch
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

# create embedded-files/ and make it avail to lede
$(FW_DIR)/embedded-files:
	mkdir $@
$(LEDE_DIR)/files: $(FW_DIR)/embedded-files
	ln -s $(FW_DIR)/embedded-files $(LEDE_DIR)/files

# lede config
$(LEDE_DIR)/.config: .stamp-patched $(TARGET_CONFIG) .stamp-build_rev $(LEDE_DIR)/dl
	cat $(TARGET_CONFIG) >$(LEDE_DIR)/.config
	# always replace CONFIG_VERSION_CODE by FW_REVISION
	sed -i "/^CONFIG_VERSION_CODE=/c\CONFIG_VERSION_CODE=\"$(FW_REVISION)\"" $(LEDE_DIR)/.config
	$(UMASK); \
	  $(MAKE) -C $(LEDE_DIR) defconfig

# prepare lede working copy
prepare: stamp-clean-prepared .stamp-prepared
.stamp-prepared: .stamp-patched $(LEDE_DIR)/.config $(LEDE_DIR)/files
	touch $@

# compile
compile: stamp-clean-compiled .stamp-compiled
.stamp-compiled: .stamp-prepared lede-clean-bin
	$(UMASK); \
	  $(MAKE) -C $(LEDE_DIR) $(MAKE_ARGS)
	touch $@

# fill firmwares-directory with:
#  * firmwares built with imagebuilder
#  * imagebuilder file
#  * packages directory
firmwares: stamp-clean-firmwares .stamp-firmwares
.stamp-firmwares: .stamp-compiled $(VERSION_FILE)
	$(eval IB_FILE := $(shell ls -tr $(LEDE_DIR)/bin/targets/$(MAINTARGET)/$(SUBTARGET)/*-imagebuilder-*.tar.xz | tail -n1))
	mkdir -p $(FW_TARGET_DIR)
	./assemble_firmware.sh -p "$(PROFILES)" -i $(IB_FILE) -e $(FW_DIR)/embedded-files -t $(FW_TARGET_DIR) -u "$(PACKAGES_LIST_DEFAULT)"
	# get relative path of firmwaredir
	$(eval RELPATH := $(shell perl -e 'use File::Spec; print File::Spec->abs2rel(@ARGV) . "\n"' "$(FW_TARGET_DIR)" "$(FW_DIR)" ))
	# shorten firmware of images to prevent some (TP-Link) firmware-upgrader from complaining
	# see https://github.com/freifunk-berlin/firmware/issues/178
	# 1) remove all "squashfs" from filenames
	for file in `find $(RELPATH) -name "freifunk-berlin-*-squashfs-*.bin"` ; do mv $$file $${file/squashfs-/}; done
	# 2) remove all TARGET names (e.g. ar71xx-generic) from filename
	for file in `find $(RELPATH) -name "freifunk-berlin-*-$(MAINTARGET)-$(SUBTARGET)-*.bin"` ; do mv $$file $${file/$(MAINTARGET)-$(SUBTARGET)-/}; done
	# copy imagebuilder, sdk and toolchain (if existing)
	# remove old versions
	rm -f $(FW_TARGET_DIR)/*.tar.xz
	for file in $(LEDE_DIR)/bin/targets/$(MAINTARGET)/$(SUBTARGET)/*{imagebuilder,sdk,toolchain}*.tar.xz; do \
	  if [ -e $$file ]; then mv $$file $(FW_TARGET_DIR)/ ; fi \
	done
	# copy packages
	PACKAGES_DIR="$(FW_TARGET_DIR)/packages"; \
	rm -rf $$PACKAGES_DIR; \
	mkdir -p $$PACKAGES_DIR/targets/$(MAINTARGET)/$(SUBTARGET)/packages; \
	cp -a $(LEDE_DIR)/bin/targets/$(MAINTARGET)/$(SUBTARGET)/packages/* $$PACKAGES_DIR/targets/$(MAINTARGET)/$(SUBTARGET)/packages; \
	# e.g. packages/packages/mips_34k the doublicated packages is correct! \
	cp -a $(LEDE_DIR)/bin/packages $$PACKAGES_DIR/
	touch $@

$(VERSION_FILE): .stamp-prepared
	mkdir -p $(FW_TARGET_DIR)
	# Create version info file
	GIT_BRANCH_ESC=$(shell $(GIT_BRANCH) | tr '/' '_'); \
	echo "https://github.com/freifunk-berlin/firmware" > $(VERSION_FILE); \
	echo "https://wiki.freifunk.net/Berlin:Firmware" >> $(VERSION_FILE); \
	echo "Firmware: git branch \"$$GIT_BRANCH_ESC\", revision $(FW_REVISION)" >> $(VERSION_FILE); \
	# add lede revision with data from config.mk \
	LEDE_REVISION=`cd $(LEDE_DIR); $(REVISION)`; \
	echo "OpenWRT: repository from $(LEDE_SRC), git branch \"$(LEDE_COMMIT)\", revision $$LEDE_REVISION" >> $(VERSION_FILE); \
	# add feed revisions \
	for FEED in `cd $(LEDE_DIR); ./scripts/feeds list -n`; do \
	  FEED_DIR=$(addprefix $(LEDE_DIR)/feeds/,$$FEED); \
	  FEED_GIT_REPO=`cd $$FEED_DIR; $(GIT_REPO)`; \
	  FEED_GIT_BRANCH_ESC=`cd $$FEED_DIR; $(GIT_BRANCH) | tr '/' '_'`; \
	  FEED_REVISION=`cd $$FEED_DIR; $(REVISION)`; \
	  echo "Feed $$FEED: repository from $$FEED_GIT_REPO, git branch \"$$FEED_GIT_BRANCH_ESC\", revision $$FEED_REVISION" >> $(VERSION_FILE); \
	done

stamp-clean-%:
	rm -f .stamp-$*

stamp-clean:
	rm -f .stamp-*

# unpatch needs "patches/" in lede
unpatch: $(LEDE_DIR)/patches
# RC = 2 of quilt --> nothing to be done
	cd $(LEDE_DIR); quilt pop -a -f || [ $$? = 2 ] && true
	rm -f .stamp-patched

clean: stamp-clean .stamp-lede-cleaned

.PHONY: lede-clean lede-clean-bin lede-update patch feeds-update prepare compile firmwares stamp-clean clean
.NOTPARALLEL:
.FORCE:
