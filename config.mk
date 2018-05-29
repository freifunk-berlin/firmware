# default parameters for Makefile
SHELL:=$(shell which bash)
TARGET=ar71xx-generic
PACKAGES_LIST_DEFAULT=default vpn03 tunnel-berlin backbone
OPENWRT_SRC=https://git.openwrt.org/openwrt/openwrt.git
OPENWRT_COMMIT=4a38c0cad5b2bfe37dd921dae04346f9a6397319
SET_BUILDBOT=env
MAKE_ARGS=
#BUILDTYPE - unstable / release
BUILDTYPE=unstable
