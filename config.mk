# default parameters for Makefile
SHELL:=$(shell which bash)
TARGET=ar71xx-generic
PACKAGES_LIST_DEFAULT=default tunnel-berlin-tunneldigger backbone
OPENWRT_SRC=https://git.openwrt.org/openwrt/openwrt.git
OPENWRT_COMMIT=db94ee62567c786bc7ca2c1ed0bcf650b77a598e
SET_BUILDBOT=env
MAKE_ARGS=V=s
