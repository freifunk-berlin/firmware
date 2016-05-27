# default parameters for Makefile
SHELL:=$(shell which bash)
TARGET=ar71xx
PACKAGES_LIST_DEFAULT=default backbone
OPENWRT_SRC=git://git.openwrt.org/15.05/openwrt.git
OPENWRT_COMMIT=64e116779c0f7da6d98068b8e7c50f528c8a91f2
MAKE_ARGS=
#BUILDTYPE - unstable / release
BUILDTYPE=unstable
