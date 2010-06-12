# $Id: Makefile 2010-02-04 23:25:21Z pg $

include $(TOPDIR)/rules.mk

PKG_NAME:=domcompat
PKG_VERSION:=20091212
PKG_RELEASE:=7
#PKG_MD5SUM:=3063643c5d200b863cf3a794c22325aa
PKG_SOURCE_URL:=http://openwrt.cloud.inolares.net/dl
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/domcompat
  SECTION:=lib
  CATEGORY:=Library
  TITLE:=domcompat
  URL:=http://inolares.net/domcompat
  DEPENDS:=
endef


define Package/domcompat/install
	$(INSTALL_DIR) $(1)/www/scripts/
	$(CP) $(PKG_BUILD_DIR)/scripts/* $(1)/www/scripts/
endef

$(eval $(call BuildPackage,domcompat))
