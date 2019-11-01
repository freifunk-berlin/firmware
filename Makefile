LC_ALL:=C
LANG:=C
export LC_ALL LANG

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

default: debug-files

## -- GLUON  -- ##

GLUON_TARGET=$(TARGET)

# check for spaces & resolve possibly relative paths
define mkabspath
 ifneq (1,$(words [$($(1))]))
  $$(error $(1) must not contain spaces)
 endif
 override $(1) := $(abspath $($(1)))
endef

GLUON_SITEDIR ?= site
$(eval $(call mkabspath,GLUON_SITEDIR))
$(GLUON_SITEDIR)/site.mk:
ifeq ($(IS_BUILDBOT),yes)
	$(info running on buildbot --> using default site-repo)
	git clone https://github.com/SvenRoederer/ffberlin-gluon-site.git site
else
	$(error No site configuration was found. Please check out a site configuration to $(GLUON_SITEDIR))
endif
include $(GLUON_SITEDIR)/site.mk

# initialize (possibly already user set) directory variables
GLUON_TMPDIR ?= tmp
GLUON_OUTPUTDIR ?= output
GLUON_IMAGEDIR ?= $(GLUON_OUTPUTDIR)/images
GLUON_PACKAGEDIR ?= $(GLUON_OUTPUTDIR)/packages
GLUON_TARGETSDIR ?= targets
GLUON_PATCHESDIR ?= patches

$(eval $(call mkabspath,GLUON_TMPDIR))
$(eval $(call mkabspath,GLUON_OUTPUTDIR))
$(eval $(call mkabspath,GLUON_IMAGEDIR))
$(eval $(call mkabspath,GLUON_PACKAGEDIR))
$(eval $(call mkabspath,GLUON_TARGETSDIR))
$(eval $(call mkabspath,GLUON_PATCHESDIR))

GLUON_WLAN_MESH ?= 11s
GLUON_DEBUG ?= 0

export GLUON_RELEASE GLUON_REGION GLUON_MULTIDOMAIN GLUON_WLAN_MESH GLUON_DEBUG GLUON_DEPRECATED GLUON_DEVICES \
	 GLUON_TARGETSDIR GLUON_PATCHESDIR GLUON_TMPDIR GLUON_IMAGEDIR GLUON_PACKAGEDIR

GLUON_TARGETS :=

define GluonTarget
gluon_target := $(1)$$(if $(2),-$(2))
GLUON_TARGETS += $$(gluon_target)
GLUON_TARGET_$$(gluon_target)_BOARD := $(1)
GLUON_TARGET_$$(gluon_target)_SUBTARGET := $(2)
endef

include $(GLUON_TARGETSDIR)/targets.mk

CheckTarget := [ '$(BOARD)' ] \
	|| (echo 'Please set GLUON_TARGET to a valid target. Gluon supports the following targets:'; $(foreach target,$(GLUON_TARGETS),echo ' * $(target)';) false)

gluon-list-targets:
	@$(foreach target,$(GLUON_TARGETS),echo '$(target)';)


OPENWRTMAKE = $(MAKE) -C openwrt V=s
BOARD := $(GLUON_TARGET_$(GLUON_TARGET)_BOARD)
SUBTARGET := $(GLUON_TARGET_$(GLUON_TARGET)_SUBTARGET)

GLUON_CONFIG_VARS := \
	GLUON_SITEDIR='$(GLUON_SITEDIR)' \
	GLUON_RELEASE='$(GLUON_RELEASE)' \
	GLUON_BRANCH='$(GLUON_BRANCH)' \
	GLUON_LANGS='$(GLUON_LANGS)' \
	BOARD='$(BOARD)' \
	SUBTARGET='$(SUBTARGET)'

GLUON_DEFAULT_PACKAGES := hostapd-mini

GLUON_FEATURE_PACKAGES := $(shell scripts/features.sh '$(GLUON_FEATURES)' || echo '__ERROR__')
ifneq ($(filter __ERROR__,$(GLUON_FEATURE_PACKAGES)),)
$(error Error while evaluating GLUON_FEATURES)
endif


GLUON_PACKAGES :=
define merge_packages
  $(foreach pkg,$(1),
    GLUON_PACKAGES := $$(strip $$(filter-out -$$(patsubst -%,%,$(pkg)) $$(patsubst -%,%,$(pkg)),$$(GLUON_PACKAGES)) $(pkg))
  )
endef
$(eval $(call merge_packages,$(GLUON_DEFAULT_PACKAGES) $(GLUON_FEATURE_PACKAGES) $(GLUON_SITE_PACKAGES)))


LUA := openwrt/staging_dir/hostpkg/bin/lua

$(LUA): $(OPENWRT_DIR)/feeds.conf
	$(CheckExternal)

	+[ -e openwrt/.config ] || $(OPENWRTMAKE) defconfig
	+$(OPENWRTMAKE) tools/install
	+$(OPENWRTMAKE) package/lua/host/compile

gluon-config: .stamp-gluon-configured_$(TARGET)
.stamp-gluon-configured_$(TARGET): .stamp-gluon-updated $(LUA)
	$(CheckExternal)
	$(GLUON_CONFIG_VARS) GLUON_FWTYPE=ffberlin \
		$(LUA) scripts/target_config.lua '$(GLUON_TARGET)' '$(GLUON_PACKAGES)' \
		> openwrt/.config
	+$(OPENWRTMAKE) defconfig

#	@$(GLUON_CONFIG_VARS) GLUON_FWTYPE=ffberlin \
#		$(LUA) scripts/target_config_check.lua '$(GLUON_TARGET)' '$(GLUON_PACKAGES)'
	touch $@

gluon-clean-openwrt:
	rm -f $(OPENWRT_DIR)/feeds.conf

gluon-update: gluon-clean-openwrt .stamp-gluon-updated $(OPENWRT_DIR)/feeds.conf .FORCE

.stamp-gluon-updated: $(OPENWRT_DIR)/feeds.conf
	touch $@

$(OPENWRT_DIR)/feeds.conf: $(FW_DIR)/modules $(wildcard $(GLUON_SITEDIR)/site.mk)
	GLUON_SITEDIR='$(GLUON_SITEDIR)' GLUON_FWTYPE=ffberlin scripts/update.sh
	GLUON_SITEDIR='$(GLUON_SITEDIR)' GLUON_FWTYPE=ffberlin scripts/patch.sh
	GLUON_SITEDIR='$(GLUON_SITEDIR)' GLUON_FWTYPE=ffberlin scripts/feeds.sh

gluon-gen-pkglist: .stamp-imagebuilder $(GLUON_TMPDIR)/images_$(GLUON_TARGET).txt
$(GLUON_TMPDIR)/images_$(GLUON_TARGET).txt: $(LUA) .stamp-gluon-configured_$(TARGET)
	$(GLUON_CONFIG_VARS) GLUON_FWTYPE=ffberlin \
		$(LUA) scripts/target_pkg.lua '$(GLUON_TARGET)' '$(GLUON_PACKAGES)' \
		> $(GLUON_TMPDIR)/images_$(GLUON_TARGET).txt

## -- GLUON  -- ##

gluon-imagebuilder: .stamp-imagebuilder_$(TARGET)
.stamp-imagebuilder_$(TARGET): .stamp-gluon-compiled_$(TARGET)
	[ -d $(FW_TARGET_DIR) ] || mkdir -p $(FW_TARGET_DIR)
	for file in $(OPENWRT_DIR)/bin/targets/$(MAINTARGET)/$(SUBTARGET)/*{imagebuilder,sdk,toolchain}*.tar.xz; do \
	  if [ -e $$file ]; then mv $$file $(FW_TARGET_DIR)/ ; fi \
	done
	touch $@

gluon-build-image: $(GLUON_TMPDIR)/images_$(GLUON_TARGET).txt .stamp-imagebuilder_$(TARGET)
	$(eval IB_FILE := $(shell ls -tr $(FW_TARGET_DIR)/*-imagebuilder-*.tar.xz | tail -n1))
	./scripts/assemble_firmware.sh -d -b $(GLUON_TMPDIR)/images_$(GLUON_TARGET).txt -i $(IB_FILE) -e $(FW_DIR)/embedded-files -t $(FW_TARGET_DIR)

# if any of the following files have been changed: clean up openwrt dir
DEPS=$(TARGET_CONFIG) feeds.conf patches $(wildcard patches/openwrt/*) $(wildcard patches/packages/*/*)

# profiles to be built (router models)
PROFILES=$(shell cat $(FW_DIR)/profiles/$(MAINTARGET)-$(SUBTARGET).profiles)

FW_REVISION=$(shell $(REVISION))

FEEDS=packages luci routing gluon

openwrt-clean-bin:
	rm -rf $(OPENWRT_DIR)/bin
	rm -rf $(OPENWRT_DIR)/build_dir/target-*/*-{imagebuilder,sdk}-*

$(FW_DIR)/modules: $(addprefix .stamp-gluon-module-,$(FEEDS)) .stamp-gluon-module-openwrt $(FW_DIR)/feeds.conf
	$(MAKE) $(addprefix .stamp-gluon-module-,$(FEEDS))
	rm -f $@
	cat >>$@ .stamp-gluon-module-openwrt
	cat >>$@ $(addprefix .stamp-gluon-module-,$(FEEDS))
	echo >>$@ GLUON_FEEDS=\'$(FEEDS)\'

.stamp-gluon-module-openwrt: $(FW_DIR)/config.mk
	rm -f $@
	echo >>$@ "OPENWRT_REPO=$(OPENWRT_SRC)"
	echo >>$@ "OPENWRT_COMMIT=$(OPENWRT_COMMIT)"
# set the $FEED-Branch
	git clone $$(grep _REPO $@ | cut -d "=" -f 2) $(GLUON_TMPDIR)/gluon_$@
	cd $(GLUON_TMPDIR)/gluon_$@; git name-rev $$(grep _COMMIT $(FW_DIR)/$@ | \
		cut -d "=" -f 2) | cut -d / -f 3 | cut -d \~ -f 1 >branchname.txt
	cd $(GLUON_TMPDIR)/gluon_$@; grep -q master branchname.txt  || \
		printf >>$(FW_DIR)/$@ "OPENWRT_BRANCH=%s\n" \
			$$(echo $* | tr '[:lower:]' '[:upper:]') \
			$$(cat branchname.txt)
	rm -rf $(GLUON_TMPDIR)/gluon_$@

.stamp-gluon-module-%: $(FW_DIR)/feeds.conf
	rm -f $@
# set the $FEED-REPO
	@echo -n "PACKAGES_$*_REPO=" | tr '[:lower:]' '[:upper:]' >>$@
	@grep -E "^src-(git|svn)[[:space:]]$*[[:space:]].*" $(FW_DIR)/feeds.conf | \
		awk -F '([[:space:]|^])' '{ print $$3 }' >>$@
# set the $FEED-COMMIT
	@echo -n "PACKAGES_$*_COMMIT=" | tr '[:lower:]' '[:upper:]' >>$@
	@grep -E "^src-(git|svn)[[:space:]]$*[[:space:]].*" $(FW_DIR)/feeds.conf | \
		awk -F '([[:space:]|^])' '{ print $$4 }' >>$@
# set the $FEED-Branch
	git clone $$(grep _REPO $@ | cut -d "=" -f 2) $(GLUON_TMPDIR)/gluon_$@
	cd $(GLUON_TMPDIR)/gluon_$@; git name-rev $$(grep _COMMIT $(FW_DIR)/$@ | \
		cut -d "=" -f 2) | cut -d / -f 3 | cut -d \~ -f 1 >branchname.txt
	cd $(GLUON_TMPDIR)/gluon_$@; grep -q master branchname.txt  || \
		printf >>$(FW_DIR)/$@ "PACKAGES_%s_BRANCH=%s\n" \
			$$(echo $* | tr '[:lower:]' '[:upper:]') \
			$$(cat branchname.txt)
	rm -rf $(GLUON_TMPDIR)/gluon_$@
	echo $@ updated

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

# compile
gluon-compile: .stamp-gluon-compiled_$(TARGET)
.stamp-gluon-compiled_$(TARGET): .stamp-gluon-configured_$(TARGET)
	+$(OPENWRTMAKE)
# check if running via buildbot and remove the build_dir folder to save some space
ifdef IS_BUILDBOT
	rm -rf $(OPENWRT_DIR)/build_dir
endif
	touch $@

debug-files: gluon-imagebuilder build-logs
	[ -d $(FW_TARGET_DIR)/debug ] || mkdir -p $(FW_TARGET_DIR)/debug
	cp $(OPENWRT_DIR)/.config $(FW_TARGET_DIR)/debug/openwrt.config
	cp $(GLUON_TMPDIR)/images_* $(FW_TARGET_DIR)/debug/

# fill firmwares-directory with:
#  * imagebuilder file
#  * packages directory
#  * firmware-images are already in place (target images)
firmwares: stamp-clean-firmwares .stamp-firmwares
.stamp-firmwares: .stamp-images $(VERSION_FILE) .stamp-initrd build-logs
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

build-logs: .stamp-gluon-compiled_$(TARGET)
	mkdir -p $(FW_TARGET_DIR)
	[ -d $(OPENWRT_DIR)/logs ] && mv $(OPENWRT_DIR)/logs $(FW_TARGET_DIR)
	touch .stamp-$@

clean-build-logs:
	rm -rf $(FW_TARGET_DIR)/logs

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

unpatch: unpatch-openwrt unpatch-feeds
	rm -f .stamp-patched

# unpatch needs "patches/" in openwrt
unpatch-openwrt:
ifneq ($(wildcard $(OPENWRT_DIR)/.pc),)
# RC = 2 of quilt --> nothing to be done
	cd $(OPENWRT_DIR); quilt pop -a -f || [ $$? = 2 ] && true
	rm -rf $(OPENWRT_DIR)/tmp
endif
	rm -f .stamp-patch-openwrt

unpatch-feeds: $(OPENWRT_DIR)/feeds.conf $(addprefix unpatch-feed-,$(FEEDS))
	$(info unpatching all feeds: $(FEEDS))
	rm -f .stamp-patch-feeds

unpatch-feed-%: $(OPENWRT_DIR)/feeds/%
	$(info this is $@)
	[ ! -d $(OPENWRT_DIR)/feeds/$*/.pc ] || \
		(cd $(OPENWRT_DIR)/feeds/$*; quilt pop -a -f || [ $$? = 2 ] && true)
	rm -f .stamp-patch-feed-$*


clean: stamp-clean .stamp-openwrt-cleaned 

.PHONY: openwrt-clean openwrt-clean-bin clean-build-logs openwrt-update patch feeds-update prepare compile firmwares stamp-clean clean
.NOTPARALLEL:
.FORCE:
.SUFFIXES:
