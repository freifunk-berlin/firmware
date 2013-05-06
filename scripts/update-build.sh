#!/bin/sh

. ./config

#MAKE=${MAKE:-nice -n 10 make}
MAKE=${MAKE:-make -j6}
#MAKE=${MAKE:-echo}

[ -z $verm ] && exit 0
[ -z $ver ] && exit 0

for board in $boards ; do
	[ -f "update-build-$verm-$board.lock" ] && echo "build $verm-$board are running. if not do rm update-build-$verm-$board.lock" && exit 0
done


update_git() {
	url="$1"
	repodir="$2"
	revision="$3"
	if [ -d $repodir ] ; then
		if [ -d $repodir/.svn ] ; then
			echo "please remove the svn repo: $repodir"
			echo "mv $repodir $repodir.bak"
			exit 0
		fi
		echo "update $repodir git pull"
		[ -z $revision ] || echo "git checkout $revision"
		cd $repodir
		git add .
		git reset --hard
		git checkout master .
		git remote rm origin
		git remote add origin $url
		git pull -u origin master || exit 0
		[ -z $revision ] || git checkout $revision || exit 0
		revision=$(git rev-parse HEAD)
		cd ../
	else
		echo "create $repodir git clone"
		git clone $url $repodir || exit 0
		cd $repodir
		[ -z $revision ] || git checkout $revision || exit 0
		revision=$(git rev-parse HEAD)
		cd ../
	fi
}

revision=""
case $verm in
	trunk)
		update_git "git://github.com/freifunk/openwrt.git" "openwrt-trunk" "$openwrt_revision"
	;;
	*)
		update_git "git://github.com/freifunk/$verm.git" "openwrt-$verm" "$openwrt_revision"
	;;
esac

if [ -f build ] ; then
    build_number="$(cat build)"
else
    build_number=0
fi
build_number=$((build_number+1))
echo $build_number > build

timestamp=`date "+%F_%H-%M"`
echo $timestamp >timestamp
date +"%Y/%m/%d %H:%M">VERSION.txt
echo "Build Nr.: $build_number on $(hostname)" >>VERSION.txt
echo "openwrt Revision: $revision"  >>VERSION.txt

[ -d feeds ] || mkdir feeds
cd feeds
cd ..
[ -d $verm/patches ] || mkdir -p $verm/patches
rm -f $verm/patches/*.patch
update_git "git://github.com/freifunk/yaffmap-agent.git" "yaffmap-agent"
echo "yaffmap-agent Revision: $revision"  >>VERSION.txt
update_git "git://github.com/freifunk/luci-app-bulletin-node.git" "luci-app-bulletin-node"
echo "luci-app-bulletin-node Revision: $revision"  >>VERSION.txt
update_git "git://github.com/freifunk/packages-pberg.git" "packages-pberg"
echo "packages-pberg Revision: $revision"  >>VERSION.txt
update_git "git://github.com/freifunk/piratenfreifunk-packages.git" "piratenfreifunk-packages"
echo "piratenfreifunk-packages Revision: $revision"  >>VERSION.txt
update_git "git://github.com/openwrt-routing/packages.git" "routing"
echo "routing packages Revision: $revision"  >>VERSION.txt

PATCHES=""
PATCHES="$PATCHES routing-olsrd.init_6and4.patch"
PATCHES="$PATCHES routing-olsrd.config-rm-wlan.patch"
cd routing
for i in $PATCHES ; do
	pparm='-p1'
	patch $pparm < ../ff-control/patches/$i || exit 0
	mkdir -p ../$verm/patches
	cp ../ff-control/patches/$i ../$verm/patches || exit 0
done
rm -rf $(find . | grep \.orig$)
cd ..


case $verm in
	trunk)
		update_git  "git://github.com/freifunk/packages.git" "packages"
		echo "packages Revision: $revision"  >>VERSION.txt
		packages_dir="packages"
	;;
	*)
		update_git  "git://github.com/freifunk/packages_$ver" "packages_$ver" >>VERSION.txt
		echo "packages Revision: $revision"  >>VERSION.txt
		packages_dir="packages_$ver"
	;;
esac

PATCHES=""
RPATCHES=""
case $verm in
	trunk)
		PATCHES="$PATCHES trunk-radvd-ifconfig.patch"
		PATCHES="$PATCHES package-pthsem-disable-eglibc-dep.patch"
		#RPATCHES="$RPATCHES packages-r31282.patch"
		;;
	attitude_adjustment)
		PATCHES="$PATCHES trunk-radvd-ifconfig.patch"
		PATCHES="$PATCHES package-openvpn-use-busybox-ip.patch"
		PATCHES="$PATCHES package-pthsem-disable-eglibc-dep.patch"
		PATCHES="$PATCHES package-pthsem-chk-linux-3.patch"
		PATCHES="$PATCHES package-nagios-plugins.patch"
		PATCHES="$PATCHES package-net-snmp.patch"
		#PATCHES="$PATCHES packages-r31282.patch"
		PATCHES="$PATCHES package-6scripts.patch"
		PATCHES="$PATCHES package-argp-standalone.patch"
		;;
esac

cd $packages_dir
for i in $PATCHES ; do
	pparm='-p1'
	patch $pparm < ../ff-control/patches/$i || exit 0
	mkdir -p ../$verm/patches
	cp ../ff-control/patches/$i ../$verm/patches || exit 0
done
for i in $RPATCHES ; do
	pparm='-p1 -R'
	patch $pparm < ../ff-control/patches/$i || exit 0
	mkdir -p ../$verm/patches
	cp ../ff-control/patches/$i ../$verm/patches || exit 0
done
rm -rf $(find . | grep \.orig$)

cd ..

update_git  "git://github.com/freifunk/luci.git" "luci-master"
echo "luci Revision: $revision"  >>VERSION.txt
cd luci-master
PATCHES=""
PATCHES="$PATCHES luci-app-olsr-use-admin-mini.patch"
PATCHES="$PATCHES luci-modfreifunk-use-admin-mini.patch"
PATCHES="$PATCHES luci-modfreifunk-use-admin-mini-status.patch"
PATCHES="$PATCHES luci-modfreifunk-use-admin-mini-makefile.patch"
PATCHES="$PATCHES luci-modfreifunk-basics-mini.patch"
PATCHES="$PATCHES luci-admin-mini-sysupgrade.patch"
PATCHES="$PATCHES luci-admin-mini-splash.patch"
PATCHES="$PATCHES luci-admin-mini-index.patch"
PATCHES="$PATCHES luci-admin-mini-backup-style.patch"
PATCHES="$PATCHES luci-admin-mini-sshkeys.patch"
PATCHES="$PATCHES luci-app-splash-css.patch"
PATCHES="$PATCHES luci-modfreifunk-migrate.patch"
PATCHES="$PATCHES luci-gwcheck-makefile.patch"
PATCHES="$PATCHES luci-theme-bootstrap.patch"
PATCHES="$PATCHES luci-theme-bootstrap-header.patch"
PATCHES="$PATCHES luci-olsr-view.patch"
PATCHES="$PATCHES luci-olsr-service-view.patch"
PATCHES="$PATCHES luci-splash-mark.patch"
PATCHES="$PATCHES luci-admin-mini-dhcp.patch"
PATCHES="$PATCHES luci-freifunk-map.patch"
PATCHES="$PATCHES luci-admin-mini-install-full.patch"
PATCHES="$PATCHES luci-admin-mini-wifi.patch"
for i in $PATCHES ; do
	pparm='-p1'
	echo "Patch: $i"
	patch $pparm < ../ff-control/patches/$i || exit 0
	mkdir -p ../$verm/patches
	cp ../ff-control/patches/$i ../$verm/patches  || exit 0
done
rm -rf $(find . | grep \.orig$)
cd ..

case $verm in
	trunk)
		sed -i -e "s,177,178," packages-pberg/net/l2gvpn/Makefile
		;;
	attitude_adjustment)
		sed -i -e "s,177,178," packages-pberg/net/l2gvpn/Makefile
		;;
esac


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

rsync_web() {
	build_profile=""
	if [ $1 ] ; then
		build_profile="/$1"
	fi
	cp build_dir/target-$arch*/root-*/usr/lib/opkg/status ../opkg-$board.status

	#timestamp
	mkdir -p	$wwwdir/$verm/$ver-timestamp/$timestamp/$board$build_profile
	rsync -lptgoDd bin/*/*	$wwwdir/$verm/$ver-timestamp/$timestamp/$board$build_profile
	rm -rf $wwwdir/$verm/$ver-timestamp/$timestamp/$board$build_profile/packages
	mkdir -p	$wwwdir/$verm/$ver-timestamp/$timestamp/$board/packages
	rsync -lptgoD bin/*/packages/*	$wwwdir/$verm/$ver-timestamp/$timestamp/$board/packages
	cp build_dir/target-$arch*/root-*/usr/lib/opkg/status $wwwdir/$verm/$ver-timestamp/$timestamp/$board$build_profile/opkg-status.txt
	cp VERSION.txt	$wwwdir/$verm/$ver-timestamp/$timestamp/$board$build_profile
	cp .config	$wwwdir/$verm/$ver-timestamp/$timestamp/$board$build_profile/config.txt

	#relativ
	rm -f	$wwwdir/$verm/$ver/$board$build_profile/*
	mkdir -p	$wwwdir/$verm/$ver/$board$build_profile
	rsync -lptgoDd bin/*/*	$wwwdir/$verm/$ver/$board$build_profile
	rm -rf $wwwdir/$verm/$ver-timestamp/$timestamp/$board$build_profile/packages
	mkdir -p $wwwdir/$verm/$ver/$board/packages
	rsync -lptgoD bin/*/packages/* $wwwdir/$verm/$ver/$board/packages
	cp build_dir/target-$arch*/root-*/usr/lib/opkg/status $wwwdir/$verm/$ver/$board$build_profile/opkg-status.txt
	cp VERSION.txt	$wwwdir/$verm/$ver/$board$build_profile
	cp .config	$wwwdir/$verm/$ver/$board$build_profile/config.txt
}

for board in $boards ; do
	echo "to see the log just type:"
	echo "tail -f update-build-$verm-$board.log"
	>update-build-$verm-$board.log
	(
	[ -f "update-build-$verm-$board.lock" ] && echo "build $verm-$board are running. if not do rm update-build-$verm-$board.lock" && return 0
	touch "update-build-$verm-$board.lock"
	echo "Board: $board"
	mkdir -p $verm/$board
	cd $verm/$board
	echo "clean up"
	rm -f .config
#	make distclean
#	rm -rf tmp
#	rm -rf feeds/*
#	rm -rf package/feeds/*
#	rm -rf bin
#	rm -rf build_dir/*/luci*
#	rm -rf build_dir/*/libiwinfo*
#	rm -rf build_dir/*/collectd*
#	rm -rf build_dir/*/root*
#	rm -rf build_dir/*/compat-wireless*
#	rm -rf build_dir/*/uhttp*
#	rm -rf build_dir
#	rm -rf staging_dir
	rm -rf files
	mkdir -p files
	case $verm in
		trunk) 
			echo "rsync --delete -a ../../openwrt-trunk/* ./"
			rsync --delete -a ../../openwrt-trunk/* ./
			rsync --delete -a ../../openwrt-trunk/.git ./
			;;
		*)
			echo "rsync  --delete -a ../../openwrt-$verm/* ./"
			rsync --delete -a ../../openwrt-$verm/* ./
			rsync --delete -a ../../openwrt-$verm/.git ./
			;;
	esac

	cp ../../VERSION.txt VERSION.txt
	echo "OpenWrt Branch: $verm" >> VERSION.txt
	echo "OpenWrt Board: $board" >> VERSION.txt
	echo "OpenWrt Build: $vername-$build_number" >> VERSION.txt
	cat ../../ff-control/patches/ascii_backfire.txt >> package/base-files/files/etc/banner
	cp VERSION.txt package/base-files/files/etc
	echo "timestamp: $timestamp url: http://$servername/$verm/$ver/$board host: $(hostname)">> package/base-files/files/etc/banner

	echo "Generate feeds.conf"
	>feeds.conf
	echo "src-link packages ../../../$packages_dir" >> feeds.conf
	echo "src-link routing ../../../routing" >> feeds.conf
	echo "src-link packagespberg ../../../packages-pberg" >> feeds.conf
	echo "src-link piratenluci ../../../piratenfreifunk-packages" >> feeds.conf
	echo "src-link luci ../../../luci-master" >> feeds.conf
	#echo "src-link wgaugsburg ../../../wgaugsburg/packages" >> feeds.conf
	echo "src-link yaffmapagent ../../../yaffmap-agent" >> feeds.conf
	echo "src-link bulletin ../../../luci-app-bulletin-node" >> feeds.conf
	#echo "src-link forkeddaapd ../../../forked-daapd" >> feeds.conf
	echo "src-link fffeeds ../../../feeds" >> feeds.conf
	echo "openwrt feeds update"
	scripts/feeds update
	echo "openwrt feeds install"
	scripts/feeds install -a
	PATCHES=""
	case $verm in
		trunk)
			PATCHES="$PATCHES kvm-hotplug-pci-config.patch"
			PATCHES="$PATCHES target-atheros-disable-pci-usb.patch" #no trunk
			PATCHES="$PATCHES whr-hp-ag108-sysupgrade.patch" #no trunk
			options_ver="CONFIG_VERSION_REPO=\"http://$servername/$verm/$ver/$board/packages\""
			;;
		attitude_adjustment)
			PATCHES="$PATCHES package-mac80211-regdb.patch"
			PATCHES="$PATCHES target-brcm2708-gzip.patch"
			PATCHES="$PATCHES target-brcm2708-kernel-config.patch"
			PATCHES="$PATCHES target-brcm2708-spi-i2c.patch"
			PATCHES="$PATCHES target-brcm2708-gpu-fw.patch"
			PATCHES="$PATCHES target-brcm2708-inittab.patch"
			PATCHES="$PATCHES kvm-hotplug-pci-config.patch"
			PATCHES="$PATCHES target-x86_kvm_guest-add-qcow.patch"
			PATCHES="$PATCHES target-ixp4xx-avila-sysupgrade.patch"
			PATCHES="$PATCHES target-atheros-disable-pci-usb.patch" #no trunk
			PATCHES="$PATCHES whr-hp-ag108-sysupgrade.patch" #no trunk
			options_ver="CONFIG_VERSION_REPO=\"http://$servername/$verm/$ver/$board/packages\""
			;;
	esac
	PATCHES="$PATCHES busybox-iproute2.patch"
	PATCHES="$PATCHES base-system.patch"
	for i in $PATCHES ; do
		pparm='-p1'
		echo "Patch: $i"
		patch $pparm < ../../ff-control/patches/$i || exit 0
		mkdir -p ../patches
		cp ../../ff-control/patches/$i ../patches || exit 0
	done
	PATCHES=""
	for i in $PATCHES ; do
		pparm='-p2 -R'
		# get patch with:
		# wget --no-check-certificate -O 'ff-control/patches/packages-r27821.patch' 'http://dev.openwrt.org/changeset/27821/branches/backfire/package?format=diff&new=27821'
		# wget --no-check-certificate -O 'ff-control/patches/packages-r27815.patch' 'http://dev.openwrt.org/changeset/27815/branches/backfire/package?format=diff&new=27815'
		echo "Patch: $i"
		patch $pparm < ../../ff-control/patches/$i || exit 0
		mkdir -p ../patches
		cp ../../ff-control/patches/$i ../patches || exit 0
	done
	rm -rf $(find package | grep \.orig$)
	rm -rf $(find target | grep \.orig$)
	
	mkdir -p ../../dl
	[ -h dl ] || ln -s ../../dl dl
	cp -a ../../ff-control/patches/regulatory.bin dl/regulatory.bin
	build_fail=0

	genconfig "CONFIG_VERSION_NUMBER=$vername-$build_number"

	case $board in
		atheros)
#########################Freifunk Minimal##########################################
			rm -f bin/*/*
			echo "copy config ../../ff-control/configs/$verm-$board.config .config"
			cp  ../../ff-control/configs/$verm-$board.config .config
			genconfig "$options_ver"
			genconfig "$options_min"
			make oldconfig
			#Disable Audio,PCI and USB#################################
			genconfig "CONFIG_AUDIO_SUPPORT=n"
			genconfig "CONFIG_PCI_SUPPORT=n"
			genconfig "CONFIG_USB_SUPPORT=n"
			${MAKE} world || build_fail=1
			rsync_web
			rm -f bin/*/*
#########################Piraten Minimal#############################################
			echo "copy config ../../ff-control/configs/$verm-$board.config .config"
			cp  ../../ff-control/configs/$verm-$board.config .config
			genconfig "$options_ver"
			genconfig "$options_min"
			genconfig "$options_pi"
			make oldconfig
			#Disable Audio,PCI and USB#################################
			genconfig "CONFIG_AUDIO_SUPPORT=n"
			genconfig "CONFIG_PCI_SUPPORT=n"
			genconfig "CONFIG_USB_SUPPORT=n"
			${MAKE} world || build_fail=1
			rsync_web "piraten"
		;;
		brcm47xx|brcm63xx)
#########################Freifunk Minimal##########################################
			rm -f bin/*/*
			echo "copy config ../../ff-control/configs/$verm-$board.config .config"
			cp  ../../ff-control/configs/$verm-$board.config .config
			genconfig "$options_ver"
			genconfig "$options_min"
			make oldconfig
			${MAKE} world || build_fail=1
			rsync_web
#########################Piraten Minimal#############################################
			rm -f bin/*/*
			echo "copy config ../../ff-control/configs/$verm-$board.config .config"
			cp  ../../ff-control/configs/$verm-$board.config .config
			genconfig "$options_ver"
			genconfig "$options_min"
			genconfig "$options_pi"
			make oldconfig
			${MAKE} world || build_fail=1
			rsync_web "piraten"
		;;
		*)
#########################Freifunk Minimal##########################################
			rm -f bin/*/*
			echo "copy config ../../ff-control/configs/$verm-$board.config .config"
			cp  ../../ff-control/configs/$verm-$board.config .config
			genconfig "$options_ver"
			genconfig "$options_min"
			make oldconfig
			${MAKE} world || build_fail=1
			rsync_web minimal
#########################Freifunk 4MB#############################################
			rm -f bin/*/*
			echo "copy config ../../ff-control/configs/$verm-$board.config .config"
			cp  ../../ff-control/configs/$verm-$board.config .config
			genconfig "$options_ver"
			genconfig "$options_4MB"
			make oldconfig
			${MAKE} world || build_fail=1
			rsync_web
#########################Piraten 4MB#############################################
			rm -f bin/*/*
			echo "copy config ../../ff-control/configs/$verm-$board.config .config"
			cp  ../../ff-control/configs/$verm-$board.config .config
			genconfig "$options_ver"
			genconfig "$options_4MB"
			genconfig "$options_pi"
			make oldconfig
			${MAKE} world || build_fail=1
			rsync_web "piraten"
			case $board in
				x86|x86_kvm_guest|brcm2708)
#########################Freifunk max##########################################
					rm -f bin/*/*
					echo "copy config ../../ff-control/configs/$verm-$board.config .config"
					cp  ../../ff-control/configs/$verm-$board.config .config
					genconfig "$options_ver"
					genconfig "$options_4MB"
					genconfig "$options_8MB"
					genconfig "$options_max"
					make oldconfig
					${MAKE} world || build_fail=1
					rsync_web "full"
#########################GA max##########################################
					rm -f bin/*/*
					echo "copy config ../../ff-control/configs/$verm-$board.config .config"
					cp  ../../ff-control/configs/$verm-$board.config .config
					genconfig "$options_ver"
					genconfig "$options_GA"
					make oldconfig
					${MAKE} world || build_fail=1
					rsync_web "ga"
				;;
				*)
#########################Freifunk 8MB##########################################
					rm -f bin/*/*
					echo "copy config ../../ff-control/configs/$verm-$board.config .config"
					cp  ../../ff-control/configs/$verm-$board.config .config
					genconfig "$options_ver"
					genconfig "$options_4MB"
					genconfig "$options_8MB"
					make oldconfig
					${MAKE} world || build_fail=1
					rsync_web "full"
				;;
			esac
		;;
	esac
	if [ $build_fail -eq 1 ] ; then
		rm ../../update-build-$verm-$board.lock
		exit 1
	fi
	cd ../../
	rm update-build-$verm-$board.lock
	) >update-build-$verm-$board.log 2>&1
	rm -rf $wwwdir/$verm/$ver/patches
	cp -a $verm/patches $wwwdir/$verm/$ver/
	cp -a $verm/patches $wwwdir/$verm/$ver-timestamp/$timestamp/
	cp update-build-$verm-$board.log $wwwdir/$verm/$ver-timestamp/$timestamp/$board/update-build-$verm-$board.log.txt
	cp update-build-$verm-$board.log $wwwdir/$verm/$ver/$board/update-build-$verm-$board.log.txt
	(
		rsync -av "$wwwdir/$verm/$ver/" "$user@$servername:$wwwdir/$verm/$ver"
		#ssh $user@$servername "rsync -av $wwwdir/$verm/$ver-timestamp/$timestamp/ $wwwdir/$verm/$ver/"
		if [ "$ca_user" != "" -a "$ca_pw" != "" ] ; then
			curl -u "$ca_user:$ca_pw" -d status="$tags New Build #$verm $ver-pberg-$build_number for #$board Boards http://$servername/$verm/$ver/$board" http://identi.ca/api/statuses/update.xml >/dev/null
		fi
	)&
	#&
	#pid=$!
	#echo $pid > update-build-$verm-$board.pid
done
echo "rsync -av $wwwdir/$verm/$ver-timestamp/$timestamp $user@$servername:$wwwdir/$verm/$ver-timestamp/"
echo "ssh $user@$servername 'rsync -av $wwwdir/$verm/$ver-timestamp/$timestamp/ $wwwdir/$verm/$ver/'"

