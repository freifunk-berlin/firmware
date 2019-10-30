# default parameters for Makefile
SHELL:=$(shell which bash)
TARGET=ar71xx-generic
PACKAGES_LIST_DEFAULT=notunnel tunnel-berlin-tunneldigger backbone
OPENWRT_SRC=https://git.openwrt.org/openwrt/openwrt.git
OPENWRT_COMMIT=2436e521b4ccc1c1fde5527604ef11bfcbbe5953
SET_BUILDBOT=env
MAKE_ARGS=V=s
