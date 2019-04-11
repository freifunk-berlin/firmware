# default parameters for Makefile
SHELL:=$(shell which bash)
TARGET=ar71xx-generic
PACKAGES_LIST_DEFAULT=default tunnel-berlin-openvpn tunnel-berlin-tunneldigger backbone
OPENWRT_SRC=https://git.openwrt.org/openwrt/openwrt.git
OPENWRT_COMMIT=b6acb7b718e3bf47f8dfa615345120aad0930bad
SET_BUILDBOT=env
MAKE_ARGS=V=s
