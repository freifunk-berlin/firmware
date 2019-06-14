# default parameters for Makefile
SHELL:=$(shell which bash)
TARGET=ar71xx-generic
PACKAGES_LIST_DEFAULT=default tunnel-berlin-tunneldigger backbone
OPENWRT_SRC=https://git.openwrt.org/openwrt/openwrt.git
OPENWRT_COMMIT=f96fbf03281a69dc48cfea90044b21e30c15b7c7
SET_BUILDBOT=env
MAKE_ARGS=V=s
