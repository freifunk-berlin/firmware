#
# Copyright (C) 2006-2009 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
# $Id: Makefile 14307 2009-07-09 13:26:57Z pg $

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

#http://www.cubic.org/~michael/dmx4linux-daily/dmx4linux-2008-11-15.tar.bz2
PKG_NAME:=dmx4linux
PKG_VERSION:=2008-11-15
PKG_RELEASE:=1
PKG_SOURCE:=dmx4linux-$(PKG_VERSION).tar.bz2
PKG_SOURCE_URL:=http://www.cubic.org/~michael/dmx4linux-daily/
#PKG_MD5SUM:=3ee301b5d0e8df9e4b915af58b725556
PKG_BUILD_DIR:=$(KERNEL_BUILD_DIR)/dmx4linux-$(PKG_VERSION)
PATCH_DIR=./patches

include $(INCLUDE_DIR)/package.mk

DMX4LINUX_FILES:= \
	$(PKG_BUILD_DIR)/drivers/dmxdev/dmxdev.$(LINUX_KMOD_SUFFIX)

#	$(PKG_BUILD_DIR)/drivers/devices/usb/usb2dmx.$(LINUX_KMOD_SUFFIX) \
#	$(PKG_BUILD_DIR)/drivers/devices/usb/ftdi2dmx.$(LINUX_KMOD_SUFFIX) \
#	$(PKG_BUILD_DIR)/drivers/devices/usb/sunlite.$(LINUX_KMOD_SUFFIX)


DMX4LINUX_AUTOLOAD:= \
	dmxdev \
	sunlite \
	ftdi2dmx \
	usb2dmx

define KernelPackage/dmx4linux
  SUBMENU:=ISDN
  TITLE:=Driver usb dmx
  URL:=http://avm.de
  FILES:=$(DMX4LINUX_FILES)
  AUTOLOAD:=$(call AutoLoad,60,dmx4linux)
  DEPENDS:=+kmod-usb2
endef


MAKE_ARGS:= \
	PATH="$(TARGET_PATH)" \
	ARCH="$(LINUX_KARCH)" \
	CROSS_COMPILE="$(TARGET_CROSS)" \
	TOOLPREFIX="$(KERNEL_CROSS)" \
	TOOLPATH="$(KERNEL_CROSS)" \
	KERNELPATH="$(LINUX_DIR)" \
	KDIR="$(LINUX_DIR)" \
	LDOPTS="--no-warn-mismatch " \
	CFLAGS="-I$(KERNEL_BUILD_DIR)/include $(TARGET_CFLAGS)" \
	KBUILD_VERBOSE=1 

#LIBDIR="$(KERNEL_BUILD_DIR)/fritz/var/lib/fritz"

define Build/Prepare
	$(call Build/Prepare/Default)
endef


#define Build/Compile
#	$(MAKE_VARS) $(MAKE) -C $(PKG_BUILD_DIR)/drivers/devices/usb $(MAKE_ARGS) 
#endef

define Build/Compile
	$(MAKE_VARS) $(MAKE) -C $(PKG_BUILD_DIR)/drivers/dmxdev $(MAKE_ARGS)
endef


$(eval $(call KernelPackage,dmx4linux))
