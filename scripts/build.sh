#!/bin/bash

# default parameters
ARCH=${ARCH:-ar71xx}
OPENWRT_SRC=${OPENWRT_SRC:-git://git.openwrt.org/openwrt.git}
OPENWRT_COMMIT=${OPENWRT_COMMIT:-65f9fd0dc881f5759a79dddee5d689e320626609}
NCPU=${NCPU:-$(cat /proc/cpuinfo | grep ^processor | wc -l)}

# cleanup openwrt dir
rm -f bin
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

# link and apply patches
ln -s ../patches .
quilt push -a || exit 1

# activate feeds
ln -s ../feeds.conf .
./scripts/feeds update && ./scripts/feeds install -a || exit 1

# copy and update (if necessary) .config
cp ../configs/${ARCH}.config .config
yes | make oldconfig || exit 1

# build!
make -j${NCPU} IGNORE_ERRORS=m || exit 1

ln -s bin/ ../bin
