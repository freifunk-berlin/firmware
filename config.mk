# default parameters for Makefile
SHELL:=$(shell which bash)
TARGET=ar71xx-generic
PACKAGES_LIST_DEFAULT=default tunnel-berlin-tunneldigger backbone
OPENWRT_SRC=https://git.openwrt.org/openwrt/openwrt.git
OPENWRT_COMMIT=a941d39460b67d2d21e86d9c73d3e9b099b2d7fb
SET_BUILDBOT=env
MAKE_ARGS=V=s
