#!/bin/bash
#
# Create version info file in root folder of firmware-target
#

set -e

. scripts/modules.sh

GIT_BRANCH_ESC=$(echo ${GIT_BRANCH} | tr '/' '_')

echo "https://github.com/freifunk-berlin/firmware" > ${VERSION_FILE}
echo "https://wiki.freifunk.net/Berlin:Firmware" >> ${VERSION_FILE}
echo "Firmware: git branch \"${GIT_BRANCH_ESC}\", revision $(${REVISION_CMD})" >> ${VERSION_FILE}
# add openwrt revision with data from config.mk
OPENWRT_REVISION=$(cd ${OPENWRT_DIR}; eval $REVISION_CMD base)
[ -z ${OPENWRT_BRANCH} ] && OPENWRT_BRANCH=master
echo "OpenWRT: repository from ${OPENWRT_REPO}, git branch \"${OPENWRT_BRANCH}\", revision ${OPENWRT_REVISION}" >> ${VERSION_FILE}
# add feed revisions
for FEED in `cd ${OPENWRT_DIR}; ./scripts/feeds list -n`; do \
  FEED_DIR=${OPENWRT_DIR}/feeds/${FEED}
  FEED_UCASE=$(echo ${FEED} | tr '[:lower:]' '[:upper:]')
  FEED_GIT_REPO=$(echo PACKAGES_${FEED_UCASE}_REPO)
  FEED_GIT_BRANCH=$(echo PACKAGES_${FEED_UCASE}_BRANCH)
  FEED_REVISION=$(cd ${FEED_DIR}; ${REVISION_CMD} base)
  [ -z ${!FEED_GIT_BRANCH} ] && export ${FEED_GIT_BRANCH}=master
  [ -z ${!FEED_GIT_REPO} ] || echo >> ${VERSION_FILE} \
    "Feed $FEED: repository from ${!FEED_GIT_REPO}, git branch \"${!FEED_GIT_BRANCH}\", revision ${FEED_REVISION}"
done
