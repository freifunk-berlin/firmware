# default parameters for Makefile
SHELL:=$(shell which bash)
TARGET=ar71xx-generic
PACKAGES_LIST_DEFAULT=notunnel tunnel-berlin-openvpn tunnel-berlin-tunneldigger backbone
OPENWRT_SRC=https://git.openwrt.org/openwrt/openwrt.git
OPENWRT_COMMIT=d9593b0809e42e9d75cc3ac4407ec30faaf70b15
SET_BUILDBOT=env
MAKE_ARGS=V=s
