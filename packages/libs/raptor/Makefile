# $Id: Makefile 2010-02-04 23:25:21Z pg $

include $(TOPDIR)/rules.mk

PKG_NAME:=raptor
PKG_VERSION:=1.4.21
PKG_RELEASE:=2

PKG_SOURCE_URL:=http://openwrt.cloud.inolares.net/dl
PKG_SOURCE:=$(PKG_NAME)-$(PKG_VERSION).tar.gz
#PKG_MD5SUM:=3063643c5d200b863cf3a794c22325aa
#PKG_BUILD_DIR:=$(BUILD_DIR)/$(PKG_NAME)-$(PKG_VERSION)
PKG_FIXUP = libtool

include $(INCLUDE_DIR)/package.mk

PKG_INSTALL=1

define Package/raptor
  SECTION:=libs
  CATEGORY:=Libraries
  TITLE:=raptor
  URL:=http://www.librdf.org
  DEPENDS:= +libcurl +libopenssl +libxslt +libxml2
endef

define Package/raptor/description
	A library for XML/RDF transformation.
endef

CONFIGURE_ARGS+= --disable-gtktest LIBS=" -Wl,-rpath-link=$(TOOLCHAIN_DIR)/lib"
TARGET_LDFLAGS+= -Wl,-rpath-link=$(STAGING_DIR)/usr/lib -Wl,-rpath-link=$(TOOLCHAIN_DIR)/lib
LDFLAGS+= -L$(TOOLCHAIN_DIR)/lib

define Build/Configure
#	( cd $(PKG_BUILD_DIR); configure; );
	$(call Build/Configure/Default)
	$(SED) 's,.*HAVE_TRUNC.*,#undef HAVE_TRUNC,g' $(PKG_BUILD_DIR)/src/raptor_config.h
endef

define Build/Compile
	$(MAKE) -C $(PKG_BUILD_DIR) \
	DESTDIR="$(PKG_INSTALL_DIR)" \
	all
endef

define Build/InstallDev
	$(INSTALL_DIR) $(1)/usr/bin $(2)/bin $(1)/usr/include $(1)/usr/lib \
		$(1)/usr/lib/pkgconfig

	$(INSTALL_BIN) \
		$(PKG_INSTALL_DIR)/usr/bin/raptor-config \
		$(2)/bin/

	ln -sf $(STAGING_DIR)/host/bin/raptor-config $(1)/usr/bin/raptor-config

	$(SED) \
		's,^\(prefix\|exec_prefix\)=.*,\1=$(STAGING_DIR)/usr,g' \
		$(2)/bin/raptor-config

	$(INSTALL_DATA) \
		$(PKG_INSTALL_DIR)/usr/include/* \
		$(1)/usr/include/

	$(CP) \
		$(PKG_INSTALL_DIR)/usr/lib/libraptor.{la,a,so*} \
		$(1)/usr/lib/

	$(INSTALL_DATA) \
		$(PKG_INSTALL_DIR)/usr/lib/pkgconfig/raptor.pc \
		$(1)/usr/lib/pkgconfig/
endef


define Package/raptor/install
	$(INSTALL_DIR) $(1)/usr/bin/
	$(INSTALL_BIN) $(PKG_BUILD_DIR)/utils/rapper $(1)/usr/bin/
	$(INSTALL_DIR) $(1)/usr/lib/
	$(CP) $(PKG_INSTALL_DIR)/usr/lib/libraptor.so* $(1)/usr/lib/
#	$(CP) ./files/* $(1)/
#	$(MAKE) -C $(PKG_BUILD_DIR) DESTDIR="$(PKG_INSTALL_DIR)" install
endef

$(eval $(call BuildPackage,raptor))
