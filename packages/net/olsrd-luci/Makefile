# 
# Copyright (C) 2009-2010 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.
# See /LICENSE for more information.
#

include $(TOPDIR)/rules.mk

PKG_BASENAME:=olsrd
PKG_NAME:=$(PKG_BASENAME)-luci
PKG_VERSION:=0.6.0
PKG_RELEASE:=1

PKG_SOURCE:=$(PKG_BASENAME)-$(PKG_VERSION).tar.bz2
PKG_SOURCE_URL:=http://www.olsr.org/releases/0.6
PKG_MD5SUM:=8425a10e315be5e061143ac310f2424b
PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
PKG_UNPACK=$(HOST_TAR) -C $(PKG_BUILD_DIR) --strip-components=1 -xjf $(DL_DIR)/$(PKG_SOURCE)

include $(INCLUDE_DIR)/package.mk

TARGET_CFLAGS += $(FPIC)

define Package/olsrd-luci/template
  SECTION:=net
  CATEGORY:=Network
  MAINTAINER:=Saverio Proto <zioproto@gmail.com>
  TITLE:=OLSR (Optimized Link State Routing) daemon
  URL:=http://www.olsr.org/
endef

define Package/olsrd-luci
  $(call Package/olsrd-luci/template)
  MENU:=1
  DEPENDS:=+libpthread
  PROVIDES:=olsrd
endef

define Package/olsrd-luci/conffiles
/etc/config/olsrd
endef

define Package/olsrd-luci-mod-arprefresh
  $(call Package/olsrd-luci/template)
  DEPENDS:=olsrd-luci
  TITLE:=Kernel ARP cache refresh plugin
endef

define Package/olsrd-luci-mod-dot-draw
  $(call Package/olsrd-luci/template)
  DEPENDS:=olsrd-luci
  TITLE:=Dot topology information plugin
endef

define Package/olsrd-luci-mod-bmf
  $(call Package/olsrd-luci/template)
  DEPENDS:=olsrd-luci +kmod-tun
  TITLE:=Basic multicast forwarding plugin
endef

define Package/olsrd-luci-mod-dyn-gw
  $(call Package/olsrd-luci/template)
  DEPENDS:=olsrd-luci
  TITLE:=Dynamic internet gateway plugin
endef

define Package/olsrd-luci-mod-dyn-gw-plain
  $(call Package/olsrd-luci/template)
  DEPENDS:=olsrd-luci
  TITLE:=Dynamic internet gateway plain plugin
endef

define Package/olsrd-luci-mod-httpinfo
  $(call Package/olsrd-luci/template)
  DEPENDS:=olsrd-luci
  TITLE:=Small informative web server plugin
endef

define Package/olsrd-luci-mod-mdns
  $(call Package/olsrd-luci/template)
  DEPENDS:=olsrd-luci
  TITLE:=Multicast DNS plugin
endef

define Package/olsrd-luci-mod-nameservice
  $(call Package/olsrd-luci/template)
  DEPENDS:=olsrd-luci
  TITLE:=Lightweight hostname resolver plugin
endef

define Package/olsrd-luci-mod-p2pd
  $(call Package/olsrd-luci/template)
  DEPENDS:=olsrd-luci
  TITLE:=Peer to Peer Discovery plugin
endef

define Package/olsrd-luci-mod-quagga
  $(call Package/olsrd-luci/template)
  DEPENDS:=olsrd-luci
  TITLE:=Quagga plugin
endef

define Package/olsrd-luci-mod-secure
  $(call Package/olsrd-luci/template)
  DEPENDS:=olsrd-luci
  TITLE:=Message signing plugin to secure routing domain
endef

define Package/olsrd-luci-mod-txtinfo
  $(call Package/olsrd-luci/template)
  DEPENDS:=olsrd-luci
  TITLE:=Small informative web server plugin
endef

define Package/olsrd-luci-mod-watchdog
  $(call Package/olsrd-luci/template)
  DEPENDS:=olsrd-luci
  TITLE:=Watchdog plugin
endef

define Package/olsrd-luci-mod-secure/conffiles
/etc/olsrd.d/olsrd_secure_key
endef

MAKE_FLAGS+= \
	NO_DEBUG_MESSAGES=1 \
	OS="linux" \
	DESTDIR="$(PKG_INSTALL_DIR)" \
	STRIP="true" \
	INSTALL_LIB="true" \
	SUBDIRS="arprefresh bmf dot_draw dyn_gw dyn_gw_plain httpinfo mdns nameservice p2pd quagga secure txtinfo watchdog" \
	all libs install install_libs

define Package/olsrd-luci/install
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) ./files/olsrd.config $(1)/etc/config/olsrd
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/olsrd $(1)/usr/sbin/
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) ./files/olsrd.init $(1)/etc/init.d/olsrd
endef

define Package/olsrd-luci-mod-arprefresh/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/lib/arprefresh/olsrd_arprefresh.so.* $(1)/usr/lib/
endef

define Package/olsrd-luci-mod-dot-draw/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/lib/dot_draw/olsrd_dot_draw.so.* $(1)/usr/lib/
endef

define Package/olsrd-luci-mod-bmf/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/lib/bmf/olsrd_bmf.so.* $(1)/usr/lib/
endef

define Package/olsrd-luci-mod-dyn-gw/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/lib/dyn_gw/olsrd_dyn_gw.so.* $(1)/usr/lib/
endef

define Package/olsrd-luci-mod-dyn-gw-plain/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/lib/dyn_gw_plain/olsrd_dyn_gw_plain.so.* $(1)/usr/lib/
endef

define Package/olsrd-luci-mod-httpinfo/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/lib/httpinfo/olsrd_httpinfo.so.* $(1)/usr/lib/
endef

define Package/olsrd-luci-mod-mdns/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/lib/mdns/olsrd_mdns.so.* $(1)/usr/lib/
endef

define Package/olsrd-luci-mod-nameservice/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/lib/nameservice/olsrd_nameservice.so.* $(1)/usr/lib/
endef

define Package/olsrd-luci-mod-p2pd/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/lib/p2pd/olsrd_p2pd.so.* $(1)/usr/lib/
endef

define Package/olsrd-luci-mod-quagga/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/lib/quagga/olsrd_quagga.so.* $(1)/usr/lib/
endef

define Package/olsrd-luci-mod-secure/install
	$(INSTALL_DIR) $(1)/etc/olsrd.d
	$(CP) ./files/olsrd_secure_key $(1)/etc/olsrd.d/
	$(INSTALL_DIR) $(1)/usr/lib
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/lib/secure/olsrd_secure.so.* $(1)/usr/lib/
endef

define Package/olsrd-luci-mod-txtinfo/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/lib/txtinfo/olsrd_txtinfo.so.* $(1)/usr/lib/
endef

define Package/olsrd-luci-mod-watchdog/install
	$(INSTALL_DIR) $(1)/usr/lib
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/lib/watchdog/olsrd_watchdog.so.* $(1)/usr/lib/
endef

$(eval $(call BuildPackage,olsrd-luci))
$(eval $(call BuildPackage,olsrd-luci-mod-arprefresh))
$(eval $(call BuildPackage,olsrd-luci-mod-dot-draw))
$(eval $(call BuildPackage,olsrd-luci-mod-bmf))
$(eval $(call BuildPackage,olsrd-luci-mod-dyn-gw))
$(eval $(call BuildPackage,olsrd-luci-mod-dyn-gw-plain))
$(eval $(call BuildPackage,olsrd-luci-mod-httpinfo))
$(eval $(call BuildPackage,olsrd-luci-mod-mdns))
$(eval $(call BuildPackage,olsrd-luci-mod-nameservice))
$(eval $(call BuildPackage,olsrd-luci-mod-p2pd))
$(eval $(call BuildPackage,olsrd-luci-mod-quagga))
$(eval $(call BuildPackage,olsrd-luci-mod-secure))
$(eval $(call BuildPackage,olsrd-luci-mod-txtinfo))
$(eval $(call BuildPackage,olsrd-luci-mod-watchdog))
