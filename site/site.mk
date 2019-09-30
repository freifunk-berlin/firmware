##	gluon site.mk makefile example

##	GLUON_FEATURES
#		Specify Gluon features/packages to enable;
#		Gluon will automatically enable a set of packages
#		depending on the combination of features listed

GLUON_FEATURES := \
	freifunk-berlin-ui \
	freifunk-berlin-defaults \
	freifunk-berlin-utils \
	freifunk-berlin-statistics-collectd \
	freifunk-berlin-mesh-olsr \
	freifunk-berlin-owm


##	GLUON_SITE_PACKAGES
#		Specify additional Gluon/OpenWrt packages to include here;
#		A minus sign may be prepended to remove a packages from the
#		selection that would be enabled by default or due to the
#		chosen feature flags

GLUON_SITE_PACKAGES := iwinfo luci-mod-admin-full luci-theme-bootstrap luci-app-ffwizard-berlin luci-mod-freifunk

#PKG_REV = $(strip $(shell \
#			set -- $$(git log -1 --format="%ct %h" --abbrev=7); \
#			secs="$$(($$1 % 86400))"; \
#			yday="$$(date --utc --date="@$$1" "+%y.%j")"; \
#			revision="$$(printf 'git-%s.%05d-%s' "$$yday" "$$secs" "$$2")"; \
#		))
PKG_REV_HASH = $(shell git log -1 --format="%h" --abbrev=7)
PKG_REV_DATE = $(shell date --date=@$$(git log -1 --format="%ct") +%y.%j)

##	DEFAULT_GLUON_RELEASE
#		version string to use for images
#		gluon relies on
#			opkg compare-versions "$1" '>>' "$2"
#		to decide if a version is newer or not.

DEFAULT_GLUON_RELEASE := gluon+exp.git-$(PKG_REV_DATE)-$(PKG_REV_HASH)

# Variables set with ?= can be overwritten from the command line

##	GLUON_RELEASE
#		call make with custom GLUON_RELEASE flag, to use your own release version scheme.
#		e.g.:
#			$ make images GLUON_RELEASE=23.42+5
#		would generate images named like this:
#			gluon-ff%site_code%-23.42+5-%router_model%.bin

GLUON_RELEASE ?= $(DEFAULT_GLUON_RELEASE)

# Default priority for updates.
GLUON_PRIORITY ?= 0

# Region code required for some images; supported values: us eu
GLUON_REGION ?= eu

# Languages to include
GLUON_LANGS ?= en de

# Do not build images for deprecated devices
GLUON_DEPRECATED ?= 0

# build broken targets by default, e.g. ar71xx-mikrotik
BROKEN ?= 1

