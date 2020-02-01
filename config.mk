# default parameters for Makefile
SHELL:=$(shell which bash)
TARGET=ar71xx-generic
PACKAGES_LIST_DEFAULT=notunnel tunnel-berlin-tunneldigger manual
OPENWRT_SRC=https://git.openwrt.org/openwrt/openwrt.git
OPENWRT_COMMIT=3d1c84d424c4f19f6e5c4c63418f033b26ec35ff
SET_BUILDBOT=env
MAKE_ARGS=V=s
