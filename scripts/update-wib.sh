#!/bin/sh

. ./config

DIR=$PWD

for board in $boards ; do
	[ -f "update-build-$verm-$board.lock" ] && echo "build update $verm-$board are running. if not do rm update-build-$verm-$board.lock" && exit 0
done

meshkit="$DIR"/"$verm"/meshkit_web
ib_tmp="$meshkit"/ib_tmp
mkdir -p $ib_tmp

for board in $boards ; do
echo "to see the log just type:"
echo "tail -f update-wib-$verm-$board.log"
rm -f $meshkit/update-wib-$verm-$board-first.lock
#>update-wib-$verm-$board.log
#(
	echo "update-wib-$verm-$board START PIDS: $p"

	target_arch=$(gcc -dumpmachine | cut -d '-' -f 1)
	target_host=$(gcc -dumpmachine | cut -d '-' -f 2)
	target="$target_host-$target_arch"

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
	
	ib_name="OpenWrt-ImageBuilder-$board$board_sub-for-$target"
	echo "$DIR"/"$verm"/"$board"/bin/*/$ib_name.tar.bz2
	if [ -f "$DIR"/"$verm"/"$board"/bin/*/$ib_name.tar.bz2 ] ; then
		echo "Find $ib_name.tar.bz2"
	else
		echo "IB not found $ib_name.tar.bz2"
		exit 0
	fi

	rm -rf $meshkit/$ib_name
	tar -xf "$DIR"/"$verm"/"$board"/bin/*/$ib_name.tar.bz2 -C $meshkit
	rsync -a --delete "$DIR"/"$verm"/"$board"/bin/*/packages $meshkit/$ib_name
	make -C $meshkit/$ib_name package_index
	sed -i $meshkit/$ib_name/packages/Packages -e '/^MD5Sum.*/d'
	touch $meshkit/$ib_name/packages/Packages.gz

	sudo rm -rf "$wwwdir"/../www-data-build/"$wibverm"-"$board$board_sub"
	sudo mkdir -p "$wwwdir"/../www-data-build/"$wibverm"-"$board$board_sub"/
	sudo rsync -av --delete "$DIR"/"$verm"/meshkit/"OpenWrt-ImageBuilder-$board$board_sub-for-$target"/ "$wwwdir"/../www-data-build/"$wibverm"-"$board$board_sub"/
	sudo chown -R www-data "$wwwdir"/../www-data-build/"$wibverm"-"$board$board_sub"/
	sudo rm -f ../www/web2py/applications/meshkit/static/package_lists/*

#	) >update-wib-$verm-$board.log 2>&1
done

echo "Rsync PIDS: $p rsync -av --delete "$DIR"/"$verm"/patches $ib_tmp"
rsync -a --delete "$DIR"/"$verm"/patches $wwwdir/$verm/$ver

