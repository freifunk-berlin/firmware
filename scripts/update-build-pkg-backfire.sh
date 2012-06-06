#!/bin/sh

. ./config

pkgname="$1"
DIR=$PWD

for board in $boards ; do
	[ -f "update-build-$verm-$board.lock" ] && echo "build $verm-$board are running. if not do rm update-build-$verm-$board.lock" && exit 0
done

for board in $boards ; do
	echo "to see the log just type:"
	echo "tail -f update-build-pkg-$verm-$board-$pkgname.log"
	(
	[ -f update-build-$verm-$board.lock ] && echo "build $verm-$board are running. if not do rm update-build-$verm-$board.lock" && exit 0
	touch update-build-$verm-$board.lock
	cd $verm/$board/
	pkgpath=""
	pkgpath=$(find package -maxdepth 1 | grep /$pkgname$)
	echo "$pkgpath"
	[ "$pkgpath" == "" ] && pkgpath=$(find package/feeds -maxdepth 2 | grep /$pkgname$)
	echo "$pkgpath"
	make $pkgpath/clean V=99 && \
	make $pkgpath/compile V=99 && \
	make $pkgpath/install V=99 && \
	make package/index && \
	mkdir -p $wwwdir/$verm/$ver/$board && \
	rsync -av --delete bin/$board/packages/ $wwwdir/$verm/$ver/$board/packages
	cd ../../
	rm update-build-$verm-$board.lock
	) >update-build-pkg-$verm-$board-$pkgname.log 2>&1 
	#&
done

# for i in $BOARD ; do
#       make -C  $DIR/OpenWrt-ImageBuilder-$i-for-$HOST_ARCH package_index
#       mkdir -p /var/www/kamikaze/$OPENWRT_VER/$i/packages
#       rsync -av --delete $DIR/OpenWrt-ImageBuilder-$i-for-$HOST_ARCH/packages /var/www/kamikaze/$OPENWRT_VER/$i
# done
