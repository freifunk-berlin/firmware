#!/bin/sh

. ./config

DIR=$PWD

for board in $boards ; do
	[ -f "update-build-$verm-$board.lock" ] && echo "build update $verm-$board are running. if not do rm update-build-$verm-$board.lock" && exit 0
done

# rm -f openwrt-wib/database/dev.db
for board in $boards ; do
#>update-wib-$board.log
#(
#  wget -O $DIR/OpenWrt-ImageBuilder-$BOARD-for-Linux-$buildarch.tar.bz2 \
#  http://firmware.leipzig.freifunk.net/kamikaze/$BOARD/OpenWrt-ImageBuilder-$BOARD-for-Linux-$buildarch.tar.bz2
  rm -rf $DIR/$verm/OpenWrt-ImageBuilder-$board-for-$buildarch
  tar -xvf $DIR/$verm/$board/bin/*/OpenWrt-ImageBuilder-$board-for-$buildarch.tar.bz2 -C $DIR/$verm
  mkdir -p $DIR/$verm/openwrt-downloads/$ver/$board/packages
  #rsync -av --delete rsync://download.openwrt.org/openwrt-downloads/kamikaze/$OPENWRT_VER/$BOARD/packages \
  #$DIR/openwrt-downloads/kamikaze/$OPENWRT_VER/$BOARD
#  cd $DIR/openwrt-downloads
#  wget --limit-rate=100k -nH -m -l 1 http://downloads.openwrt.org/$verm/$OPENWRT_VER/$BOARD/packages/
#  wget -nH -m -l 1 http://downloads.openwrt.org/$verm/$OPENWRT_VER/$BOARD/packages/
#  cd $DIR/$verm
#  mkdir -p $DIR/$verm/tmp/downloads/$OPENWRT_VER/$BOARD/packages
#  rsync -av --delete $DIR/openwrt-downloads/$verm/$OPENWRT_VER/$BOARD/packages $DIR/$verm/tmp/downloads/$OPENWRT_VER/$BOARD
#  make -C  $DIR/$verm/OpenWrt-ImageBuilder-$BOARD-for-$buildarch package_index
#  for i in $(grep "Package: " $DIR/$verm/OpenWrt-ImageBuilder-$BOARD-for-$buildarch/packages/Packages | cut -d ':' -f 2) ; do
#	echo "rm $i"
#	rm -f $DIR/$verm/tmp/downloads/kamikaze/$OPENWRT_VER/$BOARD/packages/"$i"_*
#  done
#  cp $DIR/$verm/tmp/downloads/$OPENWRT_VER/$BOARD/packages/*.ipk $DIR/$verm/OpenWrt-ImageBuilder-$BOARD-for-$buildarch/packages
  make -C  $DIR/$verm/OpenWrt-ImageBuilder-$board-for-$buildarch package_index
#  mkdir -p /var/www/kamikaze/$ver/$board/packages
#  rsync -av --delete $DIR/OpenWrt-ImageBuilder-$board-for-$buildarch/packages /var/www/kamikaze/$ver/$board
#   cd $DIR/openwrt-wib
#   if [ -f database/dev.db ] ; then
#     ./seed.pl ../OpenWrt-ImageBuilder-$BOARD-for-Linux-$buildarch
#   else
#     ./initdb.sh
#     ./seed.pl ../OpenWrt-ImageBuilder-$BOARD-for-Linux-$buildarch
#   fi
#   cd ..
#)  >update-wib-$BOARD.log 2>&1
done
