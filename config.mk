# default parameters for Makefile
SHELL:=$(shell which bash)
TARGET=ar71xx-generic
PACKAGES_LIST_DEFAULT=default tunnel-berlin-tunneldigger backbone
OPENWRT_SRC=https://git.openwrt.org/openwrt/openwrt.git
OPENWRT_COMMIT=94a1999b4feed6cfc57513252407ea85fc8e91fb
SET_BUILDBOT=env
MAKE_ARGS=V=s
