# default parameters for Makefile
SHELL:=$(shell which bash)
TARGET=ar71xx-generic
PACKAGES_LIST_DEFAULT=default tunnel-berlin-tunneldigger backbone
OPENWRT_SRC=https://git.openwrt.org/openwrt/openwrt.git
OPENWRT_COMMIT=2cb8ae20790cccf89deb15b2e0f08f36b5035cfd
SET_BUILDBOT=env
MAKE_ARGS=V=s
