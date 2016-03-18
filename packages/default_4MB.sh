#!/bin/bash

# This is a custom postinst script that gets run by a (patched)
# ImageBuilder Makefile in the target root after installing OpenWrt
# packages, just before building the SquashFS image.

echo "Deleting OLSR i18n files..."
rm -vf usr/lib/lua/luci/i18n/olsr.*
echo "deleting opkg status-files ..."
rm -rf usr/lib/opkg
rm -rf etc/opkg*
# as this will be included into image for some reason, even it's
# not listed for inclusion
echo "manually removing usign ..."
rm usr/bin/usign
rm usr/bin/signify
