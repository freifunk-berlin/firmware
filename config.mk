# default parameters for Makefile
SHELL:=$(shell which bash)
TARGET=ar71xx-generic
PACKAGES_LIST_DEFAULT=default tunnel-berlin-tunneldigger backbone
OPENWRT_SRC=https://git.openwrt.org/openwrt/openwrt.git
OPENWRT_COMMIT=0f3d54f5b70c42c2b0f7802970dac123ea0f8689
SET_BUILDBOT=env
MAKE_ARGS=V=s
