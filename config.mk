# default parameters for Makefile
SHELL:=$(shell which bash)
TARGET=ar71xx-generic
PACKAGES_LIST_DEFAULT=default tunnel-berlin-tunneldigger backbone
OPENWRT_SRC=https://git.openwrt.org/openwrt/openwrt.git
OPENWRT_COMMIT=61e51473c237db7a10c35a3da5a4eb492fa72a90
SET_BUILDBOT=env
MAKE_ARGS=V=s
