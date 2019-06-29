# default parameters for Makefile
SHELL:=$(shell which bash)
TARGET=ar71xx-generic
PACKAGES_LIST_DEFAULT=default tunnel-berlin-tunneldigger backbone
OPENWRT_SRC=https://git.openwrt.org/openwrt/openwrt.git
OPENWRT_COMMIT=4a7a8d93fa1920efbf42c5e98a637a396dac9a5c
SET_BUILDBOT=env
MAKE_ARGS=V=s
