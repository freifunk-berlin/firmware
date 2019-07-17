# default parameters for Makefile
SHELL:=$(shell which bash)
TARGET=ar71xx-generic
PACKAGES_LIST_DEFAULT=default tunnel-berlin-tunneldigger backbone
OPENWRT_SRC=https://git.openwrt.org/openwrt/openwrt.git
OPENWRT_COMMIT=96cc390d8808a79f920b6b3fd256cfeb6fd501b2
SET_BUILDBOT=env
MAKE_ARGS=V=s
