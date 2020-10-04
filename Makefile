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
TARGET_CONFIG_AUTOBUILD=$(FW_DIR)/configs/common-autobuild.config
FW_TARGET_DIR=$(FW_DIR)/firmwares/$(MAINTARGET)-$(SUBTARGET)
VERSION_FILE=$(FW_TARGET_DIR)/VERSION.txt
UMASK=umask 022

ifeq ($(SET_BUILDBOT),no)
override IS_BUILDBOT=no
else ifeq ($(SET_BUILDBOT),yes)
override IS_BUILDBOT=yes
endif

ifeq ($(IS_BUILDBOT),yes)
$(info special actions apply to builds on this host ...)
endif

# test for existing $TARGET-config or abort
ifeq ($(wildcard $(FW_DIR)/configs/$(TARGET).config),)
$(error config for $(TARGET) not defined)
endif

# if any of the following files have been changed: clean up openwrt dir
DEPS=$(TARGET_CONFIG) modules patches $(wildcard patches/*)

# profiles to be built (router models)
PROFILES=$(shell cat $(FW_DIR)/profiles/$(MAINTARGET)-$(SUBTARGET).profiles)

FW_REVISION=$(shell $(REVISION))

default: firmwares

## Gluon - Begin
# compatibility to Gluon.buildsystem
# * setup required makros and variables

# check for spaces & resolve possibly relative paths
define mkabspath
   ifneq (1,$(words [$($(1))]))
     $$(error $(1) must not contain spaces)
   endif
   override $(1) := $(abspath $($(1)))
endef

# initialize (possibly already user set) directory variables
GLUON_TMPDIR ?= tmp
GLUON_PATCHESDIR ?= patches

$(eval $(call mkabspath,GLUON_TMPDIR))
$(eval $(call mkabspath,GLUON_PATCHESDIR))

export GLUON_TMPDIR GLUON_PATCHESDIR

## Gluon - End

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

# update feeds
feeds-update: stamp-clean-feeds-updated .stamp-feeds-updated
.stamp-feeds-updated: .stamp-patched
	@$(UMASK); GLUON_SITEDIR='$(GLUON_SITEDIR)' FOREIGN_BUILD=1 scripts/feeds.sh
	touch $@

# prepare patch
pre-patch: stamp-clean-pre-patch .stamp-pre-patch
.stamp-pre-patch: $(FW_DIR)/modules
	@GLUON_SITEDIR='$(GLUON_SITEDIR)' scripts/update.sh
	touch $@

# patch openwrt and feeds working copy
patch: stamp-clean-patched .stamp-patched
.stamp-patched: .stamp-pre-patch $(wildcard $(GLUON_PATCHESDIR)/openwrt/*) $(wildcard $(GLUON_PATCHESDIR)/packages/*/*)
	@$(UMASK); GLUON_SITEDIR='$(GLUON_SITEDIR)' scripts/patch.sh
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
$(OPENWRT_DIR)/.config: .stamp-feeds-updated $(TARGET_CONFIG) $(TARGET_CONFIG_AUTOBUILD) .stamp-build_rev $(OPENWRT_DIR)/dl
ifdef IS_BUILDBOT
	cat $(TARGET_CONFIG) $(TARGET_CONFIG_AUTOBUILD) >$(OPENWRT_DIR)/.config
else
	cat $(TARGET_CONFIG) >$(OPENWRT_DIR)/.config
endif
	# always replace CONFIG_VERSION_CODE by FW_REVISION
	sed -i "/^CONFIG_VERSION_CODE=/c\CONFIG_VERSION_CODE=\"$(FW_REVISION)\"" $(OPENWRT_DIR)/.config
	$(UMASK); \
	  $(MAKE) -C $(OPENWRT_DIR) defconfig

# prepare openwrt working copy
prepare: stamp-clean-prepared .stamp-prepared
.stamp-prepared: .stamp-feeds-updated $(OPENWRT_DIR)/.config $(OPENWRT_DIR)/files
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
.stamp-firmwares: .stamp-images $(VERSION_FILE) .stamp-initrd
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

initrd: .stamp-initrd
.stamp-initrd: .stamp-compiled
	$(eval TARGET_BINDIR := $(OPENWRT_DIR)/bin/targets/$(MAINTARGET)/$(SUBTARGET))
	$(eval INITRD_DIR := $(FW_TARGET_DIR)/initrd)
	[ -d $(INITRD_DIR) ] || mkdir -p $(INITRD_DIR)
	# remove old versions
	rm -f $(INITRD_DIR)/*
	# copy initrd images (if existing)
	for file in $(TARGET_BINDIR)/*-vmlinux-initramfs.elf; do \
	  if [ -e $$file ]; then mv $$file $(INITRD_DIR)/ ; fi \
	done
	for profile in `cat profiles/$(MAINTARGET)-$(SUBTARGET).profiles`; do \
	  if [ -e $(TARGET_BINDIR)/*-$$profile-initramfs-kernel.bin ]; then mv $(TARGET_BINDIR)/*-$$profile-initramfs-kernel.bin $(INITRD_DIR)/ ; fi \
	done
	touch $@

version-file: stamp-clean-$(VERSION_FILE) $(VERSION_FILE)

$(VERSION_FILE): .stamp-prepared
	mkdir -p $(FW_TARGET_DIR)
	VERSION_FILE=$(VERSION_FILE) \
	  OPENWRT_DIR=$(OPENWRT_DIR) \
	  REVISION_CMD="$(REVISION)" \
	  GIT_BRANCH=$(shell $(GIT_BRANCH)) \
	  ./scripts/create_version-txt.sh

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
	$(UMASK); ./assemble_firmware.sh -p "$(PROFILES)" -i $(IB_FILE) -e $(FW_DIR)/embedded-files -t $(FW_TARGET_DIR) -u "$(PACKAGES_LIST_DEFAULT)"
	# get relative path of firmwaredir
	$(eval RELPATH := $(shell perl -e 'use File::Spec; print File::Spec->abs2rel(@ARGV) . "\n"' "$(FW_TARGET_DIR)" "$(FW_DIR)" ))
	# shorten firmware of images to prevent some (TP-Link) firmware-upgrader from complaining
	# see https://github.com/freifunk-berlin/firmware/issues/178
	# 1) remove all "squashfs" from filenames
	for file in `find $(RELPATH) -name "freifunk-berlin-*-squashfs-*.bin"` ; do mv $$file $${file/squashfs-/}; done
	# 2) remove all TARGET names (e.g. ar71xx-generic) from filename
	for file in `find $(RELPATH) -name "freifunk-berlin-*-$(MAINTARGET)-$(SUBTARGET)-*.bin"` ; do mv $$file $${file/$(MAINTARGET)-$(SUBTARGET)-/}; done
	touch $@

stamp-clean-firmwares:
	rm -f $(OPENWRT_DIR)/.config
	rm -f .stamp-$*

stamp-clean-$(VERSION_FILE):
	rm -f $(VERSION_FILE)

stamp-clean-%:
	rm -f .stamp-$*

stamp-clean:
	rm -f .stamp-*
	rm -rf $(GLUON_TMPDIR)

clean: stamp-clean .stamp-openwrt-cleaned

.PHONY: openwrt-clean openwrt-clean-bin patch feeds-update prepare compile firmwares stamp-clean clean
.NOTPARALLEL:
.FORCE:
.SUFFIXES:
