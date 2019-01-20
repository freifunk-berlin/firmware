# default parameters for Makefile
SHELL:=$(shell which bash)
TARGET=ar71xx-generic
PACKAGES_LIST_DEFAULT=default vpn03 tunnel-berlin tunnel-berlin-tunneldigger backbone
OPENWRT_SRC=https://git.openwrt.org/openwrt/openwrt.git
OPENWRT_COMMIT=e09592748c5c02ee34b75508e9d72e50a1e0920a
SET_BUILDBOT=env
MAKE_ARGS=
#BUILDTYPE - unstable / release
BUILDTYPE=release
