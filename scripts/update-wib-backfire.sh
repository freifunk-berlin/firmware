#!/bin/sh

. ./config

DIR=$PWD

for board in $boards ; do
	[ -f "update-build-$verm-$board.lock" ] && echo "build update $verm-$board are running. if not do rm update-build-$verm-$board.lock" && exit 0
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
		PROFILE=$profile || make_fail=1
		if [ $make_fail == 1 ] ; then
			echo "RM $build_dir"
			rm -rf $bin_dir/*
		else
			cp -a "$meshkit"/"$ib_name"/.config $bin_dir/config.txt
			echo $packages > $bin_dir/ib_packages.txt
			cp -a $build_dir/build_dir/target-*/root-*/usr/lib/opkg/status $bin_dir/opkg-status.txt
		fi

		rm -rf $build_dir
}

inc_pids() {
	limit=$1
	lockfile pids.lock
	pids=$(cat pids)
	if [ $pids -lt $limit ] ; then
		pids=$((pids+1))
		echo $pids > pids
		ret=0
	else
		ret=$limit
	fi
	rm -f pids.lock
	echo $ret
}
dec_pids() {
	lockfile pids.lock
	pids=$(cat pids)
	pids=$((pids-1))
	echo $pids > pids
	rm -f pids.lock
	echo $pids
}

rm -f pids.lock
echo 0 > pids
for board in $boards ; do
echo "to see the log just type:"
echo "tail -f update-wib-$verm-$board.log"
rm -f $meshkit/update-wib-$verm-$board-first.lock
>update-wib-$verm-$board.log
(
	limit=3
	p=$limit

	if [ -f $meshkit/update-wib-$verm-$board-first.lock ] ; then
		rand_sleep=$(($(hexdump -n1 -e\"%u\" /dev/urandom) / 3))
	else
		rand_sleep=1
		touch $meshkit/update-wib-$verm-$board-first.lock
	fi

	while [ $p -ge $limit ] ; do
		sleep $rand_sleep
		p=$(inc_pids $limit)
	done
	echo "update-wib-$verm-$board START PIDS: $p"

	if [ -f "$DIR"/"$verm"/"$board"/bin/*/OpenWrt-ImageBuilder-"$board"_generic-for-suse-i586.tar.bz2 ] ; then
		ib_name=OpenWrt-ImageBuilder-"$board"_generic-for-suse-i586
	elif [ -f "$DIR"/"$verm"/"$board"/bin/*/OpenWrt-ImageBuilder-"$board"-for-suse-i586.tar.bz2 ] ; then
		ib_name=OpenWrt-ImageBuilder-"$board"-for-suse-i586
	elif [ -f "$DIR"/"$verm"/"$board"/bin/*/OpenWrt-ImageBuilder-"$board"_au1500-for-suse-i586.tar.bz2 ] ; then
		ib_name=OpenWrt-ImageBuilder-"$board"_au1500-for-suse-i586
	else
		echo "No IB tar for $board found"
		exit 0
	fi
	rm -rf "$DIR"/"$verm"/meshkit/$ib_name
	tar -xf "$DIR"/"$verm"/"$board"/bin/*/$ib_name.tar.bz2 -C "$DIR"/"$verm"/meshkit
	rsync -a --delete "$DIR"/"$verm"/"$board"/bin/*/packages "$meshkit"/"$ib_name"
	make -C "$meshkit"/"$ib_name" package_index
	sed -i "$meshkit"/"$ib_name"/packages/Packages -e '/^MD5Sum.*/d'
	touch "$meshkit"/"$ib_name"/packages/Packages.gz
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
			#profiles="TLMR3020 TLWR1043 TLWR941"
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

			###Piraten###
			for profile in $profiles; do
				packages="$packages_ff $packages_min $packages_pi"
				build_profile $board $profile "piraten" $packages
			done
		;;
		brcm47xx|brcm63xx)
			###Freifunk###
			for profile in $profiles; do
				packages="$packages_ff $packages_min"
				build_profile $board $profile "freifunk" $packages
			done

			###Piraten###
			for profile in $profiles; do
				packages="$packages_ff $packages_min $packages_pi"
				build_profile $board $profile "piraten" $packages
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
				packages="$packages_board $packages_ff $packages_4MB $packages_vpn"
				build_profile $board $profile "vpn" $packages
			done

			###Piraten###
			for profile in $profiles; do
				packages="$packages_board $packages_ff $packages_4MB $packages_pi"
				build_profile $board $profile "piraten" $packages
			done

			case $board in
				brcm2708|x86|x86_alix2|x86_kvm_guest)
					###Full###
					for profile in $profiles; do
						packages="$packages_board $packages_ff $packages_4MB $packages_8MB $packages_max"
						build_profile $board $profile "full" $packages
					done

					###GA###
					for profile in $profiles; do
						packages="$packages_board $packages_GA"
						build_profile $board $profile "ga" $packages
					done
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
	rm -f $ib_tmp/$board/*/*/openwrt-*-vmlinux*
	rm -f $ib_tmp/$board/*/*/openwrt-*-uImage*
	rm -f $ib_tmp/$board/*/*/openwrt-*-kernel*
	rsync -a --delete $ib_tmp/$board $wwwdir/$verm/$ver
	rm -rf $ib_tmp/$board
	p=$(dec_pids)
	echo "update-wib-$verm-$board END PIDS: $p"
	) >update-wib-$verm-$board.log 2>&1 &
	sleep 1
done



>update-wib-$verm-rsync.log
(
	sleep 10
	limit=1
	p=$limit
	while [ $p -ge $limit ] ; do
		sleep 10
		p=$(inc_pids $limit)
	done
	echo "Rsync PIDS: $p rsync -av --delete "$DIR"/"$verm"/patches $ib_tmp"
	rsync -a --delete "$DIR"/"$verm"/patches $ib_tmp
	rsync -a --delete $ib_tmp/patches $wwwdir/$verm/$ver
	rsync -av --delete "$ib_tmp/" "$user@$servername:$wwwdir/$verm/$ver"
	p=$(dec_pids)
) >update-wib-$verm-rsync.log 2>&1 &

