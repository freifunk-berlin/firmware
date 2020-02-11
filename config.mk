# default parameters for Makefile
SHELL:=$(shell which bash)
TARGET=ar71xx-generic
PACKAGES_LIST_DEFAULT=notunnel tunnel-berlin-tunneldigger manual
OPENWRT_SRC=https://git.openwrt.org/openwrt/openwrt.git
OPENWRT_COMMIT=95d5cbdec34e3d29db17a2c823e3d01be1e9c283
SET_BUILDBOT=env
MAKE_ARGS=V=s
