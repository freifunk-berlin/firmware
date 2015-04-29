#!/bin/bash

# This is a custom postinst script that gets run by a (patched)
# ImageBuilder Makefile in the target root after installing OpenWrt
# packages, just before building the SquashFS image.

echo "Deleting OLSR i18n files..."
rm -vf usr/lib/lua/luci/i18n/olsr.*
