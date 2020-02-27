# default parameters for Makefile
SHELL:=$(shell which bash)
TARGET=ar71xx-generic
PACKAGES_LIST_DEFAULT=notunnel tunnel-berlin-tunneldigger manual
OPENWRT_SRC=https://git.openwrt.org/openwrt/openwrt.git
OPENWRT_COMMIT=c56ed72d2bc6dbee3ff82b4bd42e1768f1a2c737
SET_BUILDBOT=env
MAKE_ARGS=V=s
