#
# Copyright (C) 2008 OpenWrt.org
#
# This is free software, licensed under the GNU General Public License v2.


include $(TOPDIR)/rules.mk

#PKG_SOURCE_URL:=http://l2gvpn.org/l2gvpnv/
#PKG_MD5SUM:=473c310b124992df9b21189f8c93592b

PKG_BRANCH:=trunk
PKG_SOURCE_URL:=http://cloud.pberg.freifunk.net/dl/$(PKG_BRANCH)
PKG_REV:=176
#PKG_REV:=$(shell LC_ALL=C svn info ${PKG_SOURCE_URL} | sed -ne's/^Last Changed Rev: //p')

PKG_NAME:=l2gvpn
PKG_VERSION:=svn$(PKG_REV)
PKG_RELEASE:=1

PKG_SOURCE_SUBDIR:=$(PKG_NAME)-$(PKG_VERSION)
PKG_SOURCE:=$(PKG_SOURCE_SUBDIR).tar.gz
PKG_SOURCE_PROTO:=svn
PKG_SOURCE_VERSION:=$(PKG_REV)

PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)

include $(INCLUDE_DIR)/package.mk

define Package/l2gvpn
  SECTION:=net
  CATEGORY:=Network
  TITLE:=L2gvpn - OSI-Layer 2 VPN solution
  SUBMENU:=VPN
  DEPENDS:=+libpthread +kmod-tun +libuci
  URL:=http://l2gvpn.org/
endef

define Package/l2gvpn/description
	L2gvpn is a OSI-Layer 2 VPN solution which makes use of a Peer-to-Peer infrastructure
	to exchange routing information and other metadata.
	In short, you have N nodes and M (limited to 1 at the moment) supernodes. The nodes
	broadcast via the supernode until ARP and other specific meta-data is exchanged.
	After that, both directions communicate directly unless communication via a supernode
	is necessary to traverse NAT.
endef

#define Build/Prepare
#	mkdir -p $(PKG_BUILD_DIR)
#	$(CP) ./src/* $(PKG_BUILD_DIR)/
#endef

#define Build/Configure
#endef

#define Build/Compile
#	$(TARGET_CONFIGURE_OPTS) CFLAGS="$(TARGET_CFLAGS) -I$(STAGING_DIR)/usr/include \
#		-std=gnu99" LDFLAGS="$(TARGET_LDFLAGS)" $(MAKE) -C $(PKG_BUILD_DIR)
#endef

define Build/Compile
        $(MAKE) -C $(PKG_BUILD_DIR) \
	$(TARGET_CONFIGURE_OPTS) \
	CFLAGS="$(TARGET_CFLAGS) -I $(STAGING_DIR)/usr/include -std=gnu99" \
	LDFLAGS="$(TARGET_LDFLAGS)" \
	INSTALL_PROG=":"
endef


define Package/l2gvpn/install
	$(INSTALL_DIR) $(1)/usr/sbin
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/{,super}node $(1)/usr/sbin/
	$(INSTALL_DIR) $(1)/etc/init.d
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/extra/examples/l2gvpn.initscript $(1)/etc/init.d/l2gvpn
	$(INSTALL_DIR) $(1)/etc/config
	$(INSTALL_DATA) $(PKG_BUILD_DIR)/extra/examples/l2gvpn.ucisample $(1)/etc/config/l2gvpn
endef

$(eval $(call BuildPackage,l2gvpn))
