# default parameters for Makefile
SHELL:=$(shell which bash)
TARGET=ar71xx-generic
PACKAGES_LIST_DEFAULT=default tunnel-berlin-tunneldigger backbone
OPENWRT_SRC=https://git.openwrt.org/openwrt/openwrt.git
OPENWRT_COMMIT=872cbcc6280738fa9b5a7f9f7d49576405d2f18e
SET_BUILDBOT=env
MAKE_ARGS=V=s
