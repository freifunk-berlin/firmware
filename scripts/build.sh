#!/bin/bash

ARCH=ar71xx
OPENWRT_SRC=git://git.openwrt.org/openwrt.git
OPENWRT_COMMIT=f5018fd2183cd92fd67255c220314cae813cce63

# cleanup openwrt dir
if [ -d openwrt ]; then
    cd openwrt
    git clean -df && git fetch || exit 1
    rm -rf .config patches feeds.conf
else
    git clone ${OPENWRT_SRC} openwrt || exit 1
    cd openwrt
fi

# checkout specified commit
git checkout --detach ${OPENWRT_COMMIT}

# link patches, feeds and config
ln -s ../patches .
ln -s ../feeds.conf .
cp ../configs/${ARCH}.config .config

# activate feeds
./scripts/feeds update && ./scripts/feeds install -a || exit 1

# update .config if necessary
yes | make oldconfig || exit 1

# build!
make -j$(cat /proc/cpuinfo | grep ^processor | wc -l) IGNORE_ERRORS=m || exit 1

