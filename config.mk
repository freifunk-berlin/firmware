# default parameters for Makefile
SHELL:=$(shell which bash)
TARGET=ar71xx-generic
PACKAGES_LIST_DEFAULT=default vpn03 tunnel-berlin backbone
OPENWRT_SRC=https://git.openwrt.org/openwrt/openwrt.git
OPENWRT_COMMIT=7aa15953e1b60033fb1390b97fd6fe42daced738
SET_BUILDBOT=env
MAKE_ARGS=
