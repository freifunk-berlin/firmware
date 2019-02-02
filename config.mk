# default parameters for Makefile
SHELL:=$(shell which bash)
TARGET=ar71xx-generic
PACKAGES_LIST_DEFAULT=default vpn03 tunnel-berlin tunnel-berlin-tunneldigger backbone
OPENWRT_SRC=https://git.openwrt.org/openwrt/openwrt.git
OPENWRT_COMMIT=6c14b29bf1c28ca2cb171b1a46d1c880c0794f1d
SET_BUILDBOT=env
MAKE_ARGS=
#BUILDTYPE - unstable / release
BUILDTYPE=unstable
