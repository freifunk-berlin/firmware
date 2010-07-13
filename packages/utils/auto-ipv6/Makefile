# $Id: Makefile 2010-02-04 23:25:21Z pg $

include $(TOPDIR)/rules.mk

PKG_NAME:=auto-ipv6
PKG_VERSION:=0.0.1
PKG_RELEASE:=1

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/auto-ipv6
  SECTION:=luci
  CATEGORY:=LuCI
  SUBMENU:=Components
  TITLE:=Freifunk Prenzlauerberg configuration wizard
  URL:=http://pberg.freifunk.net
  DEPENDS+= \
   +luci-web +luci-app-splash
endef

define Package/auto-ipv6/description
  Freifunk Wizard for pberg
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/auto-ipv6/install
	$(INSTALL_DIR) $(1)/etc/hotplug.d/iface
	$(CP) ./src/* $(1)/etc/hotplug.d/iface
endef

$(eval $(call BuildPackage,auto-ipv6))
