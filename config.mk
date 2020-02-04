# default parameters for Makefile
SHELL:=$(shell which bash)
TARGET=ar71xx-generic
PACKAGES_LIST_DEFAULT=notunnel tunnel-berlin-tunneldigger manual
OPENWRT_SRC=https://git.openwrt.org/openwrt/openwrt.git
OPENWRT_COMMIT=2a844349fa3cd6b9ffcc82dca00fb72b4c110cee
SET_BUILDBOT=env
MAKE_ARGS=V=s
