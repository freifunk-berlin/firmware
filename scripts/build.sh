#!/bin/bash

ARCH=ar71xx
OPENWRT_SRC=git://git.openwrt.org/openwrt.git
OPENWRT_COMMIT=f5018fd2183cd92fd67255c220314cae813cce63

# cleanup openwrt dir
rm -f openwrt/patches openwrt/feeds.conf openwrt/.config

git clone ${OPENWRT_SRC} openwrt && \
    ln -s patches openwrt/ && \
    ln -s feeds.conf openwrt/ && \
    ln -s configs/${ARCH}.config openwrt/.config

cd openwrt
./scripts/feeds update
./scripts/feeds install -a
yes | make oldconfig
make -j$(cat /proc/cpuinfo | grep ^processor | wc -l) IGNORE_ERRORS=m

