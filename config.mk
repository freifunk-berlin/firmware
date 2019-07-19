# default parameters for Makefile
SHELL:=$(shell which bash)
TARGET=ar71xx-generic
PACKAGES_LIST_DEFAULT=default tunnel-berlin-tunneldigger backbone
OPENWRT_SRC=https://git.openwrt.org/openwrt/openwrt.git
OPENWRT_COMMIT=6d59f4eeb4c3d49257379499c8a43eea058f4d51
SET_BUILDBOT=env
MAKE_ARGS=V=s
