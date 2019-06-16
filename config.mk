# default parameters for Makefile
SHELL:=$(shell which bash)
TARGET=ar71xx-generic
PACKAGES_LIST_DEFAULT=default tunnel-berlin-tunneldigger backbone
OPENWRT_SRC=https://git.openwrt.org/openwrt/openwrt.git
OPENWRT_COMMIT=158a71621577c6e52dc8539a773ba62e93ed5a1f
SET_BUILDBOT=env
MAKE_ARGS=V=s
