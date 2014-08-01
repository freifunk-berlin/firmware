#!/bin/bash

# default parameters
ARCH=${ARCH:-ar71xx}
OPENWRT_SRC=${OPENWRT_SRC:-git://git.openwrt.org/openwrt.git}
OPENWRT_COMMIT=${OPENWRT_COMMIT:-65f9fd0dc881f5759a79dddee5d689e320626609}
NCPU=${NCPU:-$(cat /proc/cpuinfo | grep ^processor | wc -l)}
MAKE_CMD=${MAKE_CMD:-make -j${NCPU} IGNORE_ERRORS=m}

FIRMWARE_DIR=$(pwd)
OPENWRT_DIR=${FIRMWARE_DIR}/openwrt

# cleanup openwrt dir
rm -f ${FIRMWARE_DIR}/bin
if [ -d ${OPENWRT_DIR} ]; then
    cd ${OPENWRT_DIR}
    git clean -dff && git fetch && git reset --hard HEAD || exit 1
    rm -rf .config patches feeds.conf bin
else
    git clone ${OPENWRT_SRC} openwrt || exit 1
    cd ${OPENWRT_DIR}
fi

# checkout specified commit
git checkout --detach ${OPENWRT_COMMIT} || exit 1

# link and apply patches
ln -s ${FIRMWARE_DIR}/patches ${OPENWRT_DIR}/patches
quilt push -a || exit 1

# activate feeds
ln -s ${FIRMWARE_DIR}/feeds.conf ${OPENWRT_DIR}
./scripts/feeds uninstall -a && ./scripts/feeds update && ./scripts/feeds install -a || exit 1

# copy and update (if necessary) .config
cp ${FIRMWARE_DIR}/configs/${ARCH}.config ${OPENWRT_DIR}/.config
yes | make oldconfig || exit 1

# build!
${MAKE_CMD} || exit 1

ln -s ${OPENWRT_DIR}/bin ${FIRMWARE_DIR}/bin
