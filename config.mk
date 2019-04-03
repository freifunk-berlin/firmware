# default parameters for Makefile
SHELL:=$(shell which bash)
TARGET=ar71xx-generic
PACKAGES_LIST_DEFAULT=default tunnel-berlin-openvpn tunnel-berlin-tunneldigger backbone
OPENWRT_SRC=https://git.openwrt.org/openwrt/openwrt.git
OPENWRT_COMMIT=b3d8b3ab8e6fc0c0355f0680fc1c5f9c90a0c35a
SET_BUILDBOT=env
MAKE_ARGS=V=s
