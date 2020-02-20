# default parameters for Makefile
SHELL:=$(shell which bash)
TARGET=ar71xx-generic
PACKAGES_LIST_DEFAULT=notunnel tunnel-berlin-tunneldigger manual
OPENWRT_SRC=https://git.openwrt.org/openwrt/openwrt.git
OPENWRT_COMMIT=6b7eeb74dbf8b491b6426820bfa230fca60047dc
SET_BUILDBOT=env
MAKE_ARGS=V=s
