# default parameters for Makefile
SHELL:=$(shell which bash)
TARGET=ar71xx-generic
PACKAGES_LIST_DEFAULT=notunnel tunnel-berlin-tunneldigger manual
OPENWRT_SRC=https://git.openwrt.org/openwrt/openwrt.git
OPENWRT_COMMIT=06f5a8d3e9667ff0bfee66df5f37f40991dbe326
SET_BUILDBOT=env
MAKE_ARGS=V=s
