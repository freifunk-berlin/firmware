# default parameters for Makefile
SHELL:=$(shell which bash)
TARGET=ar71xx-generic
PACKAGES_LIST_DEFAULT=default tunnel-berlin-tunneldigger backbone
OPENWRT_SRC=https://git.openwrt.org/openwrt/openwrt.git
OPENWRT_COMMIT=28d3afc8d67231c2ad7adbde3e4b1179d0648c0e
SET_BUILDBOT=env
MAKE_ARGS=V=s
