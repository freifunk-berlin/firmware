# default parameters for Makefile
SHELL:=$(shell which bash)
TARGET=ar71xx-generic
PACKAGES_LIST_DEFAULT=notunnel tunnel-berlin-openvpn tunnel-berlin-tunneldigger backbone
OPENWRT_SRC=https://git.openwrt.org/openwrt/openwrt.git
OPENWRT_COMMIT=641f6b6c26cb9ab5e1198810015e5f4b2b5b34ad
SET_BUILDBOT=env
MAKE_ARGS=V=s
