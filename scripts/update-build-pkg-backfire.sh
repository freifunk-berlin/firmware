#!/bin/sh

. ./config

option1="$1"
DIR=$PWD

for i in $boards ; do
      cd $verm/$i/
      option2=$(find package | grep /$option1$)
      make $option2/clean V=99 && \
      make $option2/compile V=99 && \
      make $option2/install V=99 && \
      make package/index && \
      mkdir -p $wwwdir/$verm/$ver/$i && \
      rsync -av --delete bin/$i/ $wwwdir/$verm/$ver/$i
      cd ../../
done

# for i in $BOARD ; do
#       make -C  $DIR/OpenWrt-ImageBuilder-$i-for-$HOST_ARCH package_index
#       mkdir -p /var/www/kamikaze/$OPENWRT_VER/$i/packages
#       rsync -av --delete $DIR/OpenWrt-ImageBuilder-$i-for-$HOST_ARCH/packages /var/www/kamikaze/$OPENWRT_VER/$i
# done
