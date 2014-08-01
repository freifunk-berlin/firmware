#!/bin/bash

ARCH=ar71xx
OPENWRT_SRC=git://git.openwrt.org/openwrt.git
OPENWRT_COMMIT=65f9fd0dc881f5759a79dddee5d689e320626609

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

# link patches
ln -s ../patches .

# activate feeds
ln -s ../feeds.conf .
./scripts/feeds update && ./scripts/feeds install -a || exit 1

# copy config
cp ../configs/${ARCH}.config .config

# update .config if necessary
#yes | make oldconfig || exit 1

# build!
make -j$(cat /proc/cpuinfo | grep ^processor | wc -l) IGNORE_ERRORS=m || exit 1

