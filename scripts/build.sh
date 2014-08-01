#!/bin/bash

# default parameters
ARCH=${ARCH:-ar71xx}
OPENWRT_SRC=${OPENWRT_SRC:-git://git.openwrt.org/openwrt.git}
OPENWRT_COMMIT=${OPENWRT_COMMIT:-65f9fd0dc881f5759a79dddee5d689e320626609}
NCPU=${NCPU:-$(cat /proc/cpuinfo | grep ^processor | wc -l)}

PWD=$(pwd)
OPENWRT_DIR=${PWD}/openwrt

# cleanup openwrt dir
rm -f ${OPENWRT_DIR}/bin
if [ -d ${OPENWRT_DIR} ]; then
    cd ${OPENWRT_DIR}
    git clean -dff && git fetch || exit 1
    rm -rf.config patches feeds.conf
else
    git clone ${OPENWRT_SRC} openwrt || exit 1
    cd ${OPENWRT_DIR}
fi

# checkout specified commit
git checkout --detach ${OPENWRT_COMMIT} || exit 1

# link and apply patches
ln -s ${PWD}/patches ${OPENWRT_DIR}
quilt push -a || exit 1

# activate feeds
ln -s ${PWD}/feeds.conf ${OPENWRT_DIR}
./scripts/feeds update && ./scripts/feeds install -a || exit 1

# copy and update (if necessary) .config
cp ${PWD}/configs/${ARCH}.config ${OPENWRT_DIR}/.config
yes | make oldconfig || exit 1

# build!
make -j${NCPU} IGNORE_ERRORS=m || exit 1

ln -s ${OPENWRT_DIR}/bin ${PWD}/bin
