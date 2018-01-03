include config.mk

# get main- and subtarget name from TARGET
MAINTARGET=$(word 1, $(subst -, ,$(TARGET)))
SUBTARGET=$(word 2, $(subst -, ,$(TARGET)))

GIT_REPO=git config --get remote.origin.url
GIT_BRANCH=git symbolic-ref HEAD | sed -e 's,.*/\(.*\),\1,'
REVISION=git describe --always

# set dir and file names
FW_DIR=$(shell pwd)
OPENWRT_DIR=$(FW_DIR)/openwrt
TARGET_CONFIG=$(FW_DIR)/configs/common.config $(FW_DIR)/configs/$(MAINTARGET)-$(SUBTARGET).config
FW_TARGET_DIR=$(FW_DIR)/firmwares/$(MAINTARGET)-$(SUBTARGET)
VERSION_FILE=$(FW_TARGET_DIR)/VERSION.txt
UMASK=umask 022

ifeq ($(shell hostname -f),buildbot)
SET_BUILDBOT=yes
endif

ifeq ($(SET_BUILDBOT),no)
undefine IS_BUILDBOT
else
ifeq ($(SET_BUILDBOT),yes)
IS_BUILDBOT=yes
endif
endif

ifeq ($(IS_BUILDBOT),yes)
$(info special actions apply to builds on this host ...)
endif

# test for existing $TARGET-config or abort
ifeq ($(wildcard $(FW_DIR)/configs/$(TARGET).config),)
$(error config for $(TARGET) not defined)
endif

# if any of the following files have been changed: clean up openwrt dir
DEPS=$(TARGET_CONFIG) feeds.conf patches $(wildcard patches/*)

# profiles to be built (router models)
PROFILES=$(shell cat $(FW_DIR)/profiles/$(MAINTARGET)-$(SUBTARGET).profiles)

FW_REVISION=$(shell $(REVISION))

default: firmwares

# clone openwrt
$(OPENWRT_DIR):
	git clone $(OPENWRT_SRC) $(OPENWRT_DIR)

# clean up openwrt working copy
openwrt-clean: stamp-clean-openwrt-cleaned .stamp-openwrt-cleaned
.stamp-openwrt-cleaned: config.mk | $(OPENWRT_DIR) openwrt-clean-bin
	cd $(OPENWRT_DIR); \
	  ./scripts/feeds clean && \
	  git clean -dff && git fetch && git reset --hard HEAD && \
	  rm -rf .config feeds.conf build_dir/target-* logs/
	touch $@

openwrt-clean-bin:
	rm -rf $(OPENWRT_DIR)/bin
	rm -rf $(OPENWRT_DIR)/build_dir/target-*/*-{imagebuilder,sdk}-*

# update openwrt and checkout specified commit
openwrt-update: stamp-clean-openwrt-updated .stamp-openwrt-updated
.stamp-openwrt-updated: .stamp-openwrt-cleaned
	cd $(OPENWRT_DIR); git checkout --detach $(OPENWRT_COMMIT)
	touch $@

# patches require updated openwrt working copy
$(OPENWRT_DIR)/patches: | .stamp-openwrt-updated
	ln -s $(FW_DIR)/patches $@

# feeds
$(OPENWRT_DIR)/feeds.conf: .stamp-openwrt-updated feeds.conf
	cp $(FW_DIR)/feeds.conf $@

# update feeds
feeds-update: stamp-clean-feeds-updated .stamp-feeds-updated
.stamp-feeds-updated: $(OPENWRT_DIR)/feeds.conf unpatch
	cd $(OPENWRT_DIR); ./scripts/feeds uninstall -a
	cd $(OPENWRT_DIR); ./scripts/feeds update
	cd $(OPENWRT_DIR); ./scripts/feeds install -a
	touch $@

# prepare patch
pre-patch: stamp-clean-pre-patch .stamp-pre-patch
.stamp-pre-patch: .stamp-feeds-updated $(wildcard $(FW_DIR)/patches/*) | $(OPENWRT_DIR)/patches
	touch $@

# patch openwrt working copy
patch: stamp-clean-patched .stamp-patched
.stamp-patched: .stamp-pre-patch
	cd $(OPENWRT_DIR); quilt push -a
	rm -rf $(OPENWRT_DIR)/tmp
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
$(OPENWRT_DIR)/dl: $(FW_DIR)/dl
	ln -s $(FW_DIR)/dl $(OPENWRT_DIR)/dl

# create embedded-files/ and make it avail to openwrt
$(FW_DIR)/embedded-files:
	mkdir $@
$(OPENWRT_DIR)/files: $(FW_DIR)/embedded-files
	ln -s $(FW_DIR)/embedded-files $(OPENWRT_DIR)/files

# openwrt config
$(OPENWRT_DIR)/.config: .stamp-patched $(TARGET_CONFIG) .stamp-build_rev $(OPENWRT_DIR)/dl
	cat $(TARGET_CONFIG) >$(OPENWRT_DIR)/.config
	# always replace CONFIG_VERSION_CODE by FW_REVISION
	sed -i "/^CONFIG_VERSION_CODE=/c\CONFIG_VERSION_CODE=\"$(FW_REVISION)\"" $(OPENWRT_DIR)/.config
	$(UMASK); \
	  $(MAKE) -C $(OPENWRT_DIR) defconfig

# prepare openwrt working copy
prepare: stamp-clean-prepared .stamp-prepared
.stamp-prepared: .stamp-patched $(OPENWRT_DIR)/.config $(OPENWRT_DIR)/files
	touch $@

# compile
compile: stamp-clean-compiled .stamp-compiled
.stamp-compiled: .stamp-prepared openwrt-clean-bin
	$(UMASK); \
	  $(MAKE) -C $(OPENWRT_DIR) $(MAKE_ARGS)
# check if running via buildbot and remove the build_dir folder to save some space
ifdef IS_BUILDBOT
	rm -rf $(OPENWRT_DIR)/build_dir
endif
	touch $@

# fill firmwares-directory with:
#  * imagebuilder file
#  * packages directory
#  * firmware-images are already in place (target images)
firmwares: stamp-clean-firmwares .stamp-firmwares
.stamp-firmwares: .stamp-images $(VERSION_FILE)
	# copy imagebuilder, sdk and toolchain (if existing)
	# remove old versions
	rm -f $(FW_TARGET_DIR)/*.tar.xz
	for file in $(OPENWRT_DIR)/bin/targets/$(MAINTARGET)/$(SUBTARGET)/*{imagebuilder,sdk,toolchain}*.tar.xz; do \
	  if [ -e $$file ]; then mv $$file $(FW_TARGET_DIR)/ ; fi \
	done
	# copy packages
	PACKAGES_DIR="$(FW_TARGET_DIR)/packages"; \
	rm -rf $$PACKAGES_DIR; \
	mkdir -p $$PACKAGES_DIR/targets/$(MAINTARGET)/$(SUBTARGET)/packages; \
	cp -a $(OPENWRT_DIR)/bin/targets/$(MAINTARGET)/$(SUBTARGET)/packages/* $$PACKAGES_DIR/targets/$(MAINTARGET)/$(SUBTARGET)/packages; \
	# e.g. packages/packages/mips_34k the doublicated packages is correct! \
	cp -a $(OPENWRT_DIR)/bin/packages $$PACKAGES_DIR/
	touch $@

$(VERSION_FILE): .stamp-prepared
	mkdir -p $(FW_TARGET_DIR)
	# Create version info file
	GIT_BRANCH_ESC=$(shell $(GIT_BRANCH) | tr '/' '_'); \
	echo "https://github.com/freifunk-berlin/firmware" > $(VERSION_FILE); \
	echo "https://wiki.freifunk.net/Berlin:Firmware" >> $(VERSION_FILE); \
	echo "Firmware: git branch \"$$GIT_BRANCH_ESC\", revision $(FW_REVISION)" >> $(VERSION_FILE); \
	# add openwrt revision with data from config.mk \
	OPENWRT_REVISION=`cd $(OPENWRT_DIR); $(REVISION)`; \
	echo "OpenWRT: repository from $(OPENWRT_SRC), git branch \"$(OPENWRT_COMMIT)\", revision $$OPENWRT_REVISION" >> $(VERSION_FILE); \
	# add feed revisions \
	for FEED in `cd $(OPENWRT_DIR); ./scripts/feeds list -n`; do \
	  FEED_DIR=$(addprefix $(OPENWRT_DIR)/feeds/,$$FEED); \
	  FEED_GIT_REPO=`cd $$FEED_DIR; $(GIT_REPO)`; \
	  FEED_GIT_BRANCH_ESC=`cd $$FEED_DIR; $(GIT_BRANCH) | tr '/' '_'`; \
	  FEED_REVISION=`cd $$FEED_DIR; $(REVISION)`; \
	  echo "Feed $$FEED: repository from $$FEED_GIT_REPO, git branch \"$$FEED_GIT_BRANCH_ESC\", revision $$FEED_REVISION" >> $(VERSION_FILE); \
	done

images: .stamp-images

# build our firmware-images with the Imagebuilder and store them in FW_TARGET_DIR
#
# check if "IB_FILE" is defined on commandline for building just some
# firmware-images with the precomiled Imagebuilder
# if it is --> use this value for proceeding
#              and have no prerequirements for ".stamp-images"
# if it's not: --> use the IB_FILE from the regular lovcation is
#                  gets created during build, in this case a
#                  prerequirement is a build OpenWRT
ifeq ($(origin IB_FILE),command line)
.stamp-images: .FORCE
	$(info IB_FILE explicitly defined; using it for building firmware-images)
else
.stamp-images: .stamp-compiled
	$(info IB_FILE not defined; assuming called from inside regular build)
	$(eval IB_FILE := $(shell ls -tr $(OPENWRT_DIR)/bin/targets/$(MAINTARGET)/$(SUBTARGET)/*-imagebuilder-*.tar.xz | tail -n1))
endif
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
	touch $@

stamp-clean-%:
	rm -f .stamp-$*

stamp-clean:
	rm -f .stamp-*

# unpatch needs "patches/" in openwrt
unpatch: $(OPENWRT_DIR)/patches
# RC = 2 of quilt --> nothing to be done
	cd $(OPENWRT_DIR); quilt pop -a -f || [ $$? = 2 ] && true
	rm -rf $(OPENWRT_DIR)/tmp
	rm -f .stamp-patched

clean: stamp-clean .stamp-openwrt-cleaned

.PHONY: openwrt-clean openwrt-clean-bin openwrt-update patch feeds-update prepare compile firmwares stamp-clean clean
.NOTPARALLEL:
.FORCE:
