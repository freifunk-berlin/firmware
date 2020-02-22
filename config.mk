# default parameters for Makefile
SHELL:=$(shell which bash)
TARGET=ar71xx-generic
PACKAGES_LIST_DEFAULT=notunnel tunnel-berlin-tunneldigger manual
OPENWRT_SRC=https://git.openwrt.org/openwrt/openwrt.git
OPENWRT_COMMIT=b2660e67f0fb9f3398b871ad1fef5725e1b5d7d2
SET_BUILDBOT=env
MAKE_ARGS=V=s
