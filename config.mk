# default parameters for Makefile
SHELL:=$(shell which bash)
TARGET=ar71xx-generic
PACKAGES_LIST_DEFAULT=default vpn03 tunnel-berlin tunnel-berlin-tunneldigger backbone
OPENWRT_SRC=https://git.openwrt.org/openwrt/openwrt.git
OPENWRT_COMMIT=c476954633887d8a1fcd80482e821074d7c4a36e
SET_BUILDBOT=env
MAKE_ARGS=
#BUILDTYPE - unstable / release
BUILDTYPE=unstable
