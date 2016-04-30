#!/bin/bash

# This is a custom postinst script that gets run by a (patched)
# ImageBuilder Makefile in the target root after installing OpenWrt
# packages, just before building the SquashFS image.

echo "Deleting OLSR i18n files..."
rm -vf usr/lib/lua/luci/i18n/olsr.*
echo "deleting opkg status-files ..."
rm -rf usr/lib/opkg
rm -rf etc/opkg*
# see https://github.com/freifunk-berlin/firmware/pull/341 &
#  https://github.com/freifunk-berlin/firmware/issues/262
cat > lib/upgrade/keep.d/freiunk-berlin_no-opkg-info-on-4mb-workaround <<KEEPLIST
/etc/iproute2/rt_tables
/etc/firewall.user
/etc/vnstat.conf
KEEPLIST
# as this will be included into image for some reason, even it's
# not listed for inclusion
echo "manually removing usign ..."
rm usr/bin/usign
rm usr/bin/signify
