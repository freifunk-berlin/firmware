#!/bin/sh

. ./config

DIR=$PWD

for board in $boards ; do
	[ -f "update-build-$verm-$board.lock" ] && echo "build update $verm-$board are running. if not do rm update-build-$verm-$board.lock" && exit 1
done

ib_tmp="$DIR"/"$verm"/meshkit/ib_tmp
mkdir -p $ib_tmp
meshkit="$DIR"/"$verm"/meshkit


build_profile() {
		board=$1
		profile=$2
		pname=$3
		bin_dir="$ib_tmp/$board/$pname/$profile"
		rm -rf $bin_dir
		mkdir -p $bin_dir

		build_dir="$ib_tmp-build/$board/$pname/$profile"
		rm -rf $build_dir
		mkdir -p $build_dir

		for i in include Makefile packages repositories.conf rules.mk scripts\
		staging_dir target .config .packageinfo .targetinfo ; do
			ln -s "$meshkit"/"$ib_name"/$i $build_dir/
		done
		mkdir -p $build_dir/build_dir
		rsync -a --delete "$meshkit"/"$ib_name"/build_dir $build_dir

		echo "Build Board: $board Profile: $profile pname: $pname"
		echo "Packages: $packages"

		touch $build_dir/packages/Packages.gz
		make_fail=0
		make -C $build_dir image \
		DEVICE_TYPE="" PACKAGES="$packages" \
		BIN_DIR=$bin_dir \
		PROFILE=$profile
		# || make_fail=1

		#if [ "$make_fail" == "1" ] ; then
		#	echo "RM $build_dir"
		#	rm -rf $bin_dir/*
		#else
			cp -a "$meshkit"/"$ib_name"/.config $bin_dir/config.txt
			echo $packages > $bin_dir/ib_packages.txt
			cp -a $build_dir/build_dir/target-*/root-*/usr/lib/opkg/status $bin_dir/opkg-status.txt
		#fi

		rm -rf $build_dir
}

for board in $boards ; do
echo "to see the log just type:"
echo "tail -f update-ib-$verm-$board.log"
rm -f $meshkit/update-ib-$verm-$board-first.lock
>update-ib-$verm-$board.log
(
	echo "update-ib-$verm-$board START PIDS: $p"

	target_arch=$(gcc -dumpmachine | cut -d '-' -f 1)
	target_host=$(gcc -dumpmachine | cut -d '-' -f 2)
	target="$target_host-$target_arch"

	case $verm in
		attitude_adjustment) ibverm="Attitude-Adjustment" ;;
		barrier_breaker) ibverm="Barrier-Breaker" ;;
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
	if [ -f "$DIR"/"$verm"/"$board"/bin/*/$ib_name.tar.bz2 ] ; then
		echo "Find $ib_name.tar.bz2"
	else
		echo "IB not found $ib_name.tar.bz2"
		exit 1
	fi

	rm -rf "$DIR"/"$verm"/meshkit/$ib_name
	tar -xf "$DIR"/"$verm"/"$board"/bin/*/$ib_name.tar.bz2 -C "$DIR"/"$verm"/meshkit
	rsync -a --delete "$DIR"/"$verm"/"$board"/bin/*/packages "$meshkit"/"$ib_name"
	make -C "$meshkit"/"$ib_name" package_index
	sed -i "$meshkit"/"$ib_name"/packages/Packages -e '/^MD5Sum.*/d'
	touch "$meshkit"/"$ib_name"/packages/Packages.gz

	sudo rm -rf "$wwwdir"/../www-data-build/"$ibverm"-"$board$board_sub"
	sudo mkdir -p "$wwwdir"/../www-data-build/"$ibverm"-"$board$board_sub"/
	sudo rsync -av --delete "$DIR"/"$verm"/meshkit/"OpenWrt-ImageBuilder-$board$board_sub-for-$target"/ "$wwwdir"/../www-data-build/"$ibverm"-"$board$board_sub"/
	sudo chown -R www-data "$wwwdir"/../www-data-build/"$ibverm"-"$board$board_sub"/
	sudo rm -f ../www/web2py/applications/meshkit/static/package_lists/*


	packages_board=""
	case $board in
		atheros|x86_alix2)
			profiles="Generic"
			;;
		brcm2708)
			profiles=$(make -C "$meshkit"/"$ib_name" info | grep :$ | tail -n +2 | cut -d ":" -f 1)
			packages_board="$packages_brcm2708"
			;;
		x86_kvm_guest)
			profiles="Generic"
			packages_board="$packages_x86_kvm_guest"
			;;
		ar71xx)
			profiles=$(make -C "$meshkit"/"$ib_name" info | grep :$ \
			| tail -n +2 | cut -d ":" -f 1 | grep -v ath5k | grep -v Default \
			| grep -v Minimal | grep -v PB92 | grep -v TEW712BR \
			| grep -v WP543 | grep -v WPE72 | grep -v NBG_460N_550N_550NH \
			| grep -v JA76PF | grep -v EWDORIN | grep -v ALL0305 \
			| grep -v ALFAAP96 | grep -v ^AP*)
			#profiles="TLWDR4300"
			#profiles="TLMR3020"
			#profiles="TLMR3020 TLWDR4300 TLWR1043"
			;;
		at91)
			profiles="Generic"
			;;
		*)
			profiles=$(make -C "$meshkit"/"$ib_name" info | grep :$ | tail -n +2 | cut -d ":" -f 1)
			;;
	esac

	rm -rf $ib_tmp/$board
	case $board in
		atheros)
			###Freifunk###
			for profile in $profiles; do
				packages="$packages_ff $packages_min"
				build_profile $board $profile "freifunk" $packages
			done

		;;
		brcm47xx|brcm63xx)
			###Freifunk###
			for profile in $profiles; do
				packages="$packages_ff $packages_min"
				build_profile $board $profile "freifunk" $packages
			done

		;;
		*)
			###Freifunk###
			for profile in $profiles; do
				packages="$packages_board $packages_ff $packages_4MB"
				build_profile $board $profile "freifunk" $packages
			done

			###Minimal###
			for profile in $profiles; do
				packages="$packages_board $packages_ff $packages_min"
				build_profile $board $profile "minimal" $packages
			done

			###VPN###
			for profile in $profiles; do
				packages="$packages_board $packages_ff $packages_vpn"
				build_profile $board $profile "vpn" $packages
			done

			case $board in
				brcm2708|x86|x86_alix2|x86_kvm_guest|at91)
					###Full###
					for profile in $profiles; do
						packages="$packages_board $packages_ff $packages_4MB $packages_8MB $packages_max"
						build_profile $board $profile "full" $packages
					done

					###GA###
					#for profile in $profiles; do
					#	packages="$packages_board $packages_GA"
					#	build_profile $board $profile "ga" $packages
					#done
					;;
				*)
					###Full###
					for profile in $profiles; do
						packages="$packages_board $packages_ff $packages_4MB $packages_8MB"
						build_profile $board $profile "full" $packages
					done
					;;
			esac
		;;
	esac
	rsync -a --delete "$meshkit"/"$ib_name"/packages $ib_tmp/$board/
	mkdir -p $wwwdir/$verm/$ver
	rm -f $ib_tmp/$board/*/*/openwrt-*-root*
	rm -f $ib_tmp/$board/*/*/openwrt-*-vmlinuz*
	case $board in
		au1000);;
		*)
			rm -f $ib_tmp/$board/*/*/openwrt-*-vmlinux*
		;;
	esac
	rm -f $ib_tmp/$board/*/*/openwrt-*-uImage*
	rm -f $ib_tmp/$board/*/*/openwrt-*-kernel*
	rsync -a --delete $ib_tmp/$board $wwwdir/$verm/$ver
	rsync -a "$DIR"/"$verm"/"$board"/bin/*/$ib_name.tar.bz2 $wwwdir/$verm/$ver/
	rm -rf $ib_tmp/$board
	echo "update-ib-$verm-$board END PIDS: $p"
	) >update-ib-$verm-$board.log 2>&1
done



echo "Rsync PIDS: $p rsync -av --delete "$DIR"/"$verm"/patches $ib_tmp"
cp -a "$DIR"/firmware-berlin/Changelog $wwwdir/$verm/$ver
rsync -a --delete "$DIR"/"$verm"/patches $wwwdir/$verm/$ver

