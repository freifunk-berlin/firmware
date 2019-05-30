# default parameters for Makefile
SHELL:=$(shell which bash)
TARGET=ar71xx-generic
PACKAGES_LIST_DEFAULT=default vpn03 tunnel-berlin tunnel-berlin-tunneldigger backbone
OPENWRT_SRC=https://git.openwrt.org/openwrt/openwrt.git
OPENWRT_COMMIT=fab672cc7aa9b619f69af4ca8bed94f4b8feff03
SET_BUILDBOT=env
MAKE_ARGS=
#BUILDTYPE - unstable / release
BUILDTYPE=release
