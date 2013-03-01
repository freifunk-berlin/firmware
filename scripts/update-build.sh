#!/bin/sh

. ./config

#MAKE=${MAKE:-nice -n 10 make}
MAKE=${MAKE:-make -j2}
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
		#rmf="$(git diff --cached | grep 'diff --git a' | cut -d ' ' -f 3 | cut -b 3-)"
		#[ -z "$rmf" ] || rm "$rmf"
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


timestamp=`date "+%F_%H-%M"`
echo $timestamp >timestamp
date +"%Y/%m/%d %H:%M">VERSION.txt
echo "Build on $(hostname)" >>VERSION.txt
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
#update_git "git://github.com/freifunk/packages-pberg.git" "packages-pberg"
echo "packages-pberg Revision: $revision"  >>VERSION.txt
update_git "git://github.com/freifunk/piratenfreifunk-packages.git" "piratenfreifunk-packages"
echo "piratenfreifunk-packages Revision: $revision"  >>VERSION.txt

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

case $verm in
	trunk)
		PACKAGESPATCHES="$PACKAGESPATCHES trunk-radvd-ifconfig.patch"
		PACKAGESPATCHES="$PACKAGESPATCHES trunk-olsrd.init_6and4-patches.patch"
		PACKAGESPATCHES="$PACKAGESPATCHES package-pthsem-disable-eglibc-dep.patch"
		#PACKAGESRPATCHES="$PACKAGESRPATCHES packages-r31282.patch"
		;;
	attitude_adjustment)
		PACKAGESPATCHES="$PACKAGESPATCHES trunk-radvd-ifconfig.patch"
		PACKAGESPATCHES="$PACKAGESPATCHES trunk-olsrd.init_6and4-patches.patch"
		PACKAGESPATCHES="$PACKAGESPATCHES package-openvpn-devel-use-busybox-ip.patch"
		PACKAGESPATCHES="$PACKAGESPATCHES package-pthsem-disable-eglibc-dep.patch"
		#PACKAGESRPATCHES="$PACKAGESRPATCHES packages-r31282.patch"
		;;
	*)
		#PACKAGESPATCHES="$PACKAGESPATCHES radvd-ifconfig.patch" #no trunk
		PACKAGESPATCHES="$PACKAGESPATCHES package-radvd.patch" #no trunk
		#PACKAGESPATCHES="$PACKAGESPATCHES olsrd.init_6and4-patches.patch" #no trunk
		PACKAGESPATCHES="$PACKAGESPATCHES package-olsrd.patch" #no trunk
		PACKAGESPATCHES="$PACKAGESPATCHES package-collectd.patch" #no trunk
		PACKAGESPATCHES="$PACKAGESPATCHES package-libmodbus-3.1.0.patch"
		;;
esac
PACKAGESPATCHES="$PACKAGESPATCHES olsrd.config-rm-wlan-patches.patch"

cd $packages_dir
for i in $PACKAGESPATCHES ; do
	pparm='-p0'
	patch $pparm < ../ff-control/patches/$i || exit 0
	mkdir -p ../$verm/patches
	cp ../ff-control/patches/$i ../$verm/patches || exit 0
done
for i in $PACKAGESRPATCHES ; do
	pparm='-p1 -R'
	#echo "Patch: $i"
	patch $pparm < ../ff-control/patches/$i || exit 0
	mkdir -p ../$verm/patches
	cp ../ff-control/patches/$i ../$verm/patches || exit 0
done
rm -rf $(find . | grep \.orig$)
rm libs/argp-standalone/patches/001-throw-in-funcdef.patch

cd ..

update_git  "git://github.com/freifunk/luci.git" "luci-master"
echo "luci Revision: $revision"  >>VERSION.txt
cd luci-master
#REMOVE LUCIPATCHES="$LUCIPATCHES luci-profile_muenster.patch"
#REMOVE LUCIPATCHES="$LUCIPATCHES luci-profile_cottbus.patch"
#REMOVE LUCIPATCHES="$LUCIPATCHES luci-profile_ndb.patch"
#REMOVE LUCIPATCHES="$LUCIPATCHES luci-profile_ffwtal.patch"
LUCIPATCHES="$LUCIPATCHES luci-app-olsr-use-admin-mini.patch"
LUCIPATCHES="$LUCIPATCHES luci-modfreifunk-use-admin-mini.patch"
LUCIPATCHES="$LUCIPATCHES luci-modfreifunk-use-admin-mini-status.patch"
LUCIPATCHES="$LUCIPATCHES luci-modfreifunk-use-admin-mini-makefile.patch"
LUCIPATCHES="$LUCIPATCHES luci-modfreifunk-basics-mini.patch"
LUCIPATCHES="$LUCIPATCHES luci-admin-mini-sysupgrade.patch"
LUCIPATCHES="$LUCIPATCHES luci-admin-mini-splash.patch"
LUCIPATCHES="$LUCIPATCHES luci-admin-mini-index.patch"
LUCIPATCHES="$LUCIPATCHES luci-admin-mini-backup-style.patch"
LUCIPATCHES="$LUCIPATCHES luci-admin-mini-sshkeys.patch"
LUCIPATCHES="$LUCIPATCHES luci-freifunk_radvd_gvpn.patch"
LUCIPATCHES="$LUCIPATCHES luci-app-splash-css.patch"
LUCIPATCHES="$LUCIPATCHES luci-modfreifunk-migrate.patch"
LUCIPATCHES="$LUCIPATCHES luci-gwcheck-makefile.patch"
LUCIPATCHES="$LUCIPATCHES luci-theme-bootstrap.patch"
LUCIPATCHES="$LUCIPATCHES luci-theme-bootstrap-header.patch"
LUCIPATCHES="$LUCIPATCHES luci-olsr-view.patch"
LUCIPATCHES="$LUCIPATCHES luci-olsr-service-view.patch"
LUCIPATCHES="$LUCIPATCHES luci-splash-mark.patch"
LUCIPATCHES="$LUCIPATCHES luci-admin-mini-dhcp.patch"
LUCIPATCHES="$LUCIPATCHES luci-freifunk-map.patch"
LUCIPATCHES="$LUCIPATCHES luci-admin-mini-install-full.patch"
LUCIPATCHES="$LUCIPATCHES luci-admin-mini-wifi.patch"
for i in $LUCIPATCHES ; do
	pparm='-p1'
	echo "Patch: $i"
	patch $pparm < ../ff-control/patches/$i || exit 0
	mkdir -p ../$verm/patches
	cp ../ff-control/patches/$i ../$verm/patches  || exit 0
done

rm -rf modules/freifunk/luasrc/controller/freifunk/remote_update.lua
rm -rf modules/freifunk/luasrc/view/freifunk/remote_update.htm
rm -rf contrib/package/freifunk-firewall/files/etc/hotplug.d/iface/22-firewall-nat-fix
rm -rf $(find . | grep \.orig$)
cd ..

case $verm in
	trunk)
		sed -i -e "s,177,178," packages-pberg/net/l2gvpn/Makefile
		;;
	attitude_adjustment)
		sed -i -e "s,177,178," packages-pberg/net/l2gvpn/Makefile
		;;
	*)
		sed -i -e "s,178,177," packages-pberg/net/l2gvpn/Makefile
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
	#rm -rf $(svn status)
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
	#echo "git add ."
	#git add .
	#rmf="$(git diff --cached | grep 'diff --git a' | cut -d ' ' -f 3 | cut -b 3-)"
	#[ -z "$rmf" ] || rm "$rmf"
	#git reset --hard
	#git checkout master .

	#openwrt_revision=$(svn info | grep Revision | cut -d ' ' -f 2)
	cp ../../VERSION.txt VERSION.txt
	echo "OpenWrt Branch: $verm" >> VERSION.txt
	echo "OpenWrt Board: $board" >> VERSION.txt
	cat ../../ff-control/patches/ascii_backfire.txt >> package/base-files/files/etc/banner
	cp VERSION.txt package/base-files/files/etc
	echo "timestamp: $timestamp url: http://$servername/$verm/$ver/$board host: $(hostname)">> package/base-files/files/etc/banner

	echo "Generate feeds.conf"
	>feeds.conf
	echo "src-link packages ../../../$packages_dir" >> feeds.conf
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
	case $verm in
		trunk)
			#PATCHES="$PATCHES trunk-base-passwd-admin.patch"
			#PATCHES="$PATCHES trunk-atheros-config.patch"
			#rm -f package/base-files/files/etc/shadow
			case $board in
				x86_kvm_guest)
					PATCHES="$PATCHES kvm-hotplug-pci-config.patch"
				;;
				atheros)
					PATCHES="$PATCHES aa-atheros-disable-pci-usb.patch" #no trunk
					PATCHES="$PATCHES whr-hp-ag108-sysupgrade.patch" #no trunk
				;;
			esac
			options_ver="CONFIG_VERSION_REPO=\"http://$servername/$verm/$ver/$board/packages\""
			;;
		attitude_adjustment)
			PATCHES="$PATCHES package-mac80211-regdb.patch"
			case $board in
				x86_kvm_guest)
					PATCHES="$PATCHES kvm-hotplug-pci-config.patch"
					PATCHES="$PATCHES target-x86_kvm_guest-add-qcow.patch"
				;;
				atheros)
					PATCHES="$PATCHES aa-atheros-disable-pci-usb.patch" #no trunk
					PATCHES="$PATCHES whr-hp-ag108-sysupgrade.patch" #no trunk
				;;
			esac
			options_ver="CONFIG_VERSION_REPO=\"http://$servername/$verm/$ver/$board/packages\""
			;;
		*)
			sed -i -e 's/\(DISTRIB_DESCRIPTION=".*\)"/\1 (r'$openwrt_revision') build date: '$timestamp'"/' package/base-files/files/etc/openwrt_release
			options_ver="CONFIG_VERSION_REPO=\"http://$servername/$verm/$ver/$board/packages\""
			PATCHES="$PATCHES base-disable-ipv6-autoconf.patch" #no trunk
			PATCHES="$PATCHES base-passwd-admin.patch"
			PATCHES="$PATCHES package-lua.patch"
			PATCHES="$PATCHES package-dnsmasq-trunk.patch"
			PATCHES="$PATCHES package-dnsmasq-ff-timing.patch"
			PATCHES="$PATCHES package-libubox.patch"
			PATCHES="$PATCHES sven-ola-luks.patch"
			case $board in
				ar71xx)
					PATCHES="$PATCHES routerstation-bridge-wan-lan.patch" #no trunk
					PATCHES="$PATCHES routerstation-pro-bridge-wan-lan.patch" #no trunk
					PATCHES="$PATCHES ar71xx-package-mac80211-platform-compat.patch"
				;;
				atheros)
					PATCHES="$PATCHES atheros-disable-pci-usb.patch" #no trunk
					PATCHES="$PATCHES whr-hp-ag108-sysupgrade.patch" #no trunk
					PATCHES="$PATCHES package-mac80211-platform-compat.patch"
				;;
				ixp4xx)
					PATCHES="$PATCHES  target-ixp4xx-avila-sysupgrade.patch" #no trunk
					PATCHES="$PATCHES package-mac80211-platform-compat.patch"
				;;
				x86_kvm_guest)
#					PATCHES="$PATCHES x86-virtio-usb-boot.patch"
					PATCHES="$PATCHES add-qcow-images.patch"
					PATCHES="$PATCHES package-mac80211-platform-compat.patch"
				;;
#				x86)
#					PATCHES="$PATCHES x86-usb-boot.patch"
#					PATCHES="$PATCHES package-mac80211-platform-compat.patch"
#				;;
				*)
					PATCHES="$PATCHES package-mac80211-platform-compat.patch"
				;;
			esac
			PATCHES="$PATCHES package-crda-regulatory-pberg.patch"
			PATCHES="$PATCHES package-crda-backport.patch"
			PATCHES="$PATCHES package-iw-3.3.patch"
			PATCHES="$PATCHES package-libnl-tiny-backport.patch"
			PATCHES="$PATCHES package-mac80211-trunk.patch"
			PATCHES="$PATCHES package-mac80211-backport.patch"
			PATCHES="$PATCHES package-wireless-tools-backport.patch"
			PATCHES="$PATCHES package-iwinfo-backport.patch"
			PATCHES="$PATCHES package-hostapd-backport.patch"
			;;
	esac
	PATCHES="$PATCHES busybox-iproute2.patch"
	PATCHES="$PATCHES base-system.patch"
	#PATCHES="$PATCHES package-mac80211-dir300.patch"
	#PATCHES="$PATCHES package-mac80211.patch"
	#PATCHES="$PATCHES make-art-writeable.patch"
	for i in $PATCHES ; do
		pparm='-p0'
		echo "Patch: $i"
		patch $pparm < ../../ff-control/patches/$i || exit 0
		mkdir -p ../patches
		cp ../../ff-control/patches/$i ../patches || exit 0
	done
	#RPATCHES="$RPATCHES packages-r27821.patch"
	#RPATCHES="$RPATCHES packages-r27815.patch"
	for i in $RPATCHES ; do
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
				x86|x86_kvm_guest)
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
			curl -u "$ca_user:$ca_pw" -d status="$tags New Build #$verm $ver-rc1-pberg for #$board Boards http://$servername/$verm/$ver/$board" http://identi.ca/api/statuses/update.xml >/dev/null
		fi
	)&
	#&
	#pid=$!
	#echo $pid > update-build-$verm-$board.pid
done
echo "rsync -av $wwwdir/$verm/$ver-timestamp/$timestamp $user@$servername:$wwwdir/$verm/$ver-timestamp/"
echo "ssh $user@$servername 'rsync -av $wwwdir/$verm/$ver-timestamp/$timestamp/ $wwwdir/$verm/$ver/'"

