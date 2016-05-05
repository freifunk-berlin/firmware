#!/bin/bash

# This is a custom postinst script that gets run by a (patched)
# ImageBuilder Makefile in the target root after installing OpenWrt
# packages, just before building the SquashFS image.

echo "Deleting OLSR i18n files..."
rm -vf usr/lib/lua/luci/i18n/olsr.*

# see https://github.com/freifunk-berlin/firmware/pull/341 &
#  https://github.com/freifunk-berlin/firmware/issues/262
cat > lib/upgrade/freiunk-berlin_no-opkg-info-on-4mb-workaround.sh <<'KEEPLIST'
# check for opkg-conffiles that have changed 
# this is a workaround for removing opkg from the image and having something
# similar to "opkg list-changed-conffiles"

add_opkg_fix_conffiles()
{
	local filelist="$1"

	# find the separator line (### opkg conffiles ###) and check all files listed there
	# it's just the list of conffiles extracted from opkg-/status during image-creation
	content_separator_line=`sed -n '/^### opkg conffiles ###/=' /lib/upgrade/freiunk-berlin_no-opkg-info-on-4mb-workaround.sh`
	let content_separator_line++
	# iterate over all lines after "separator line"
	tail -n +$content_separator_line /lib/upgrade/freiunk-berlin_no-opkg-info-on-4mb-workaround.sh | \
		while read filename; do
			file_has_changed ${filename} && echo ${filename} >> $filelist
		done
}

file_has_changed() {
	if cmp -s "$@" "/rom/$@"; then
		return 1
	else
		# modified
		return 0
	fi
}

sysupgrade_init_conffiles="$sysupgrade_init_conffiles add_opkg_fix_conffiles"

# to exit before going down to the filelist
return 0

### opkg conffiles ###
KEEPLIST

# this is run during firmware-image creation
# add all conffiles known to opkg
echo "adding opkg-conffiles to sysupgrade-hook"
for file in `cat usr/lib/opkg/info/*.conffiles`; do
 grep ${file} usr/lib/opkg/status | awk '{ print $1 }' >>lib/upgrade/freiunk-berlin_no-opkg-info-on-4mb-workaround.sh
done

echo "deleting opkg status-files ..."
rm -rf usr/lib/opkg
rm -rf etc/opkg*
# as this will be included into image for some reason, even it's
# not listed for inclusion
echo "manually removing usign ..."
rm usr/bin/usign
rm usr/bin/signify
