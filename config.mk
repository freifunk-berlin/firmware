# default parameters for Makefile
SHELL:=$(shell which bash)
TARGET=ar71xx-generic
PACKAGES_LIST_DEFAULT=default tunnel-berlin-tunneldigger backbone
OPENWRT_SRC=https://git.openwrt.org/openwrt/openwrt.git
OPENWRT_COMMIT=afce041e2bbe44126a5908ec9bf1d18f5177603b
SET_BUILDBOT=env
MAKE_ARGS=V=s
