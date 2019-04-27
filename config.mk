# default parameters for Makefile
SHELL:=$(shell which bash)
TARGET=ar71xx-generic
PACKAGES_LIST_DEFAULT=default tunnel-berlin-openvpn tunnel-berlin-tunneldigger backbone
OPENWRT_SRC=https://git.openwrt.org/openwrt/openwrt.git
OPENWRT_COMMIT=9af2735734fce61eaf9bdb49fff218e6548af6f2
SET_BUILDBOT=env
MAKE_ARGS=V=s
