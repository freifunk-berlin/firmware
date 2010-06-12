#
# Copyright (C) 2006-2009 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#
# $Id: Makefile 14307 2009-07-09 13:26:57Z pg $

include $(TOPDIR)/rules.mk
include $(INCLUDE_DIR)/kernel.mk

PKG_NAME:=fcpci
PKG_VERSION:=3.11-07
PKG_RELEASE:=2
PKG_SOURCE:=fcpci-suse93-$(PKG_VERSION).tar.gz
PKG_SOURCE_URL:=ftp://ftp.avm.de/cardware/fritzcrd.pci/linux/suse.93/
PKG_MD5SUM:=3ee301b5d0e8df9e4b915af58b725556
PKG_CAT:=zcat
PKG_BUILD_DIR:=$(KERNEL_BUILD_DIR)/fritz
PATCH_DIR=./patches

#-$(PKG_VERSION)
include $(INCLUDE_DIR)/package.mk

FCPCI_FILES:= $(PKG_BUILD_DIR)/src/fcpci.$(LINUX_KMOD_SUFFIX)

FCPCI_AUTOLOAD:= fcpci

define KernelPackage/fcpci
  SUBMENU:=ISDN
  TITLE:=Driver for FritzCard
  URL:=http://avm.de
  FILES:=$(FCPCI_FILES)
  AUTOLOAD:=$(call AutoLoad,60,fcpci)
  DEPENDS:=+kmod-capi @PCI_SUPPORT||TARGET_atheros @!TARGET_ar7 @!TARGET_avr32 @!TARGET_etrax @!TARGET_uml
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
	LIBDIR="$(KERNEL_BUILD_DIR)/fritz/var/lib/fritz" \
	CFLAGS="$(TARGET_CFLAGS)" \

define Build/Prepare
	$(call Build/Prepare/Default)
endef


define Build/Compile
        $(MAKE_VARS) $(MAKE) -C $(PKG_BUILD_DIR)/src $(MAKE_ARGS) 
endef


$(eval $(call KernelPackage,fcpci))
