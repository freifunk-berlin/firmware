# default parameters for Makefile
SHELL:=$(shell which bash)
TARGET=ar71xx-generic
PACKAGES_LIST_DEFAULT=default backbone
OPENWRT_SRC=git://github.com/openwrt/openwrt.git
OPENWRT_COMMIT=9a1fd3e313cedf1e689f6f4e342528ed27c09766
MAKE_ARGS=
#BUILDTYPE - unstable / release
BUILDTYPE=release
