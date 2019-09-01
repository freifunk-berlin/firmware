# default parameters for Makefile
SHELL:=$(shell which bash)
TARGET=ar71xx-generic
PACKAGES_LIST_DEFAULT=default tunnel-berlin-tunneldigger backbone
OPENWRT_SRC=https://git.openwrt.org/openwrt/openwrt.git
OPENWRT_COMMIT=4fb6b8c553f692eeb5bcb203e0f8ee8df099e77e
SET_BUILDBOT=env
MAKE_ARGS=V=s
