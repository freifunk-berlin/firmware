#!/bin/sh


genconfig() {
	key_val_list="$1"
	if ! [ -z "$key_val_list" ] ; then
		for i in $key_val_list ; do
			i1=$(echo $i|cut -d '=' -f1)
			i2=$(echo $i|cut -d '=' -f2)
			if grep ^$i1= .config ; then
				echo "mod $i1=$i2"
				sed -i -e "s,^$i1=.*,$i1=$i2," .config
			elif grep "^# $i1 " .config ; then
				echo "akt $i1=$i2"
				sed -i -e "s,^# $i1 .*,$i1=$i2," .config
			else
				echo "add $i1=$i2"
				echo "$i1=$i2" >> .config
			fi
		done
	fi
}


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
	echo "openwrt feeds update"
	scripts/feeds update
	echo "openwrt feeds install"
	scripts/feeds install -a
	pkgpath=""
	pkgpath="$(find package -maxdepth 1 | grep /$pkgname$)"
	#[ -z "$pkgpath" ] && pkgpath=$(find package -maxdepth 2 | grep /$pkgname$)
	[ -z "$pkgpath" ] && pkgpath=$(find package -maxdepth 3 | grep /$pkgname$)
	[ -z "$pkgpath" ] && pkgpath=$(find package/feeds -maxdepth 2 | grep /$pkgname$)
	[ -z "$pkgpath" ] && echo "$pkgname not found" && rm update-build-$verm-$board.lock && break
	cp ../../firmware-berlin/configs/$verm-$board.config .config
	make oldconfig
	make $pkgpath/clean V=99 && \
	make $pkgpath/compile V=99 && \
	make $pkgpath/install V=99 && \
	make package/index && \
	mkdir -p $wwwdir/$verm/$ver/$board/packages && \
	rsync -lptgoDv bin/*/packages/* $wwwdir/$verm/$ver/$board/packages
	case $verm in
		attitude_adjustment) wibverm="Attitude-Adjustment" ;;
		barrier_breaker) wibverm="Barrier-Breaker" ;;
	esac
	board_sub=""
	case $board in
		ar71xx) board_sub="_generic" ;;
		at91) board_sub="_9g20" ;;
		atheros) board_sub="" ;;
		au1000) board_sub="_au1500" ;;
		brcm2708) board_sub="" ;;
		brcm47xx) board_sub="" ;;
		brcm63xx) board_sub="" ;;
		ixp4xx) board_sub="_generic" ;;
		mpc85xx) board_sub="_generic" ;;
		x86) board_sub="_generic" ;;
		x86_alix2) board_sub="" ;;
		x86_kvm_guest) board_sub="" ;;
	esac
	sudo rsync -av --delete bin/*/packages "$wwwdir"/../www-data-build/"$wibverm"-"$board$board_sub"/
	sudo chown -R www-data "$wwwdir"/../www-data-build/"$wibverm"-"$board$board_sub"/packages
	sudo chown -R www-data "$wwwdir"/../www-data-build/"$wibverm"-"$board$board_sub"/packages/*
	sudo touch "$wwwdir"/../www-data-build/"$wibverm"-"$board$board_sub"/packages/Packages.gz
	sudo rm -f ../www/web2py/applications/meshkit/static/package_lists/*
	cd ../../
	rm update-build-$verm-$board.lock
	) >update-build-pkg-$verm-$board-$pkgname.log 2>&1
done

