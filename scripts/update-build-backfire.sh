#!/bin/sh

. ./config

MAKE=${MAKE:-nice -n 10 make}

for board in $boards ; do
	[ -f "update-build-$verm-$board.lock" ] && echo "build $verm-$board are running. if not do rm update-build-$verm-$board.lock" && exit 0
done

case $verm in
	trunk) 
		svn co svn://svn.openwrt.org/openwrt/trunk ./openwrt-trunk  || exit 0
	;;
	*)
		svn co svn://svn.openwrt.org/openwrt/branches/$verm ./openwrt-$verm || exit 0
	;;
esac
if [ $openwrt_revision ] ; then
	case $verm in
		trunk) 
			cd openwrt-trunk
			svn sw -r $openwrt_revision svn://svn.openwrt.org/openwrt/trunk || exit 0
			cd ..
			;;
		*)
			cd openwrt-$verm
			svn sw -r $openwrt_revision svn://svn.openwrt.org/openwrt/branches/$verm || exit 0
			cd ..
			;;
	esac
fi



timestamp=`date "+%F_%H-%M"`
echo $timestamp >timestamp
date +"%Y/%m/%d %H:%M">VERSION.txt
echo "Build on $(hostname)" >>VERSION.txt

[ -d feeds ] || mkdir feeds
cd feeds
cd ..
[ -d $verm/patches ] || mkdir $verm/patches
rm -f $verm/patches/*.patch

if [ -d yaffmap-agent ] ; then
	echo "update yaffmap-agent git pull"
	cd yaffmap-agent
	git pull origin master || exit 0
	[ -z $yaffmap_agent_revision ] || git checkout $yaffmap_agent_revision || exit 0
	yaffmap_agent_revision=$(git rev-parse HEAD)
	cd ../
else
	echo "create yaffmap-agent git clone"
	git clone git://github.com/freifunk/yaffmap-agent.git || exit 0
	cd yaffmap-agent
	[ -z $yaffmap_agent_revision ] || git checkout $yaffmap_agent_revision || exit 0
	yaffmap_agent_revision=$(git rev-parse HEAD)
	cd ../
fi
echo "yaffmap-agent Revision: $yaffmap_agent_revision" >> VERSION.txt

if [ -d luci-app-bulletin-node ] ; then
	echo "update luci-app-bulletin-node git pull"
	cd luci-app-bulletin-node
	git reset --hard
	git pull origin master || exit 0
	[ -z $luci_app_bulletin_node_revision ] || git checkout $luci_app_bulletin_node_revision || exit 0
	luci_app_bulletin_node_revision=$(git rev-parse HEAD)
	cd ../
else
	echo "create luci-app-bulletin-node git clone"
	git clone git://github.com/freifunk/luci-app-bulletin-node.git || exit 0
	cd luci-app-bulletin-node
	[ -z $luci_app_bulletin_node_revision ] || git checkout $luci_app_bulletin_node_revision || exit 0
	luci_app_bulletin_node_revision=$(git rev-parse HEAD)
	cd ../
fi
echo "luci-app-bulletin-node Revision: $luci_app_bulletin_node_revision" >> VERSION.txt


case $verm in
	trunk)
		packages_dir='packages'
		if [ -d $packages_dir ] ; then
			echo "update $packages_dir svn up"
			cd $packages_dir
			rm -rf $(svn status)
			if [ -z $packages_revision ] ; then
				svn up  || exit 0
			else
				svn sw -r $packages_revision "svn://svn.openwrt.org/openwrt/$packages_dir"  || exit 0
			fi
			packages_revision=$(svn info | grep Revision | cut -d ' ' -f 2)
			cd ../
		else
			echo "create $packages_dir svn co"
			svn co "svn://svn.openwrt.org/openwrt/$packages_dir"
			if [ -z $packages_revision ] ; then
				svn co "svn://svn.openwrt.org/openwrt/$packages_dir"
			else
				svn co "svn://svn.openwrt.org/openwrt/$packages_dir"
				cd $packages_dir
				svn sw -r $packages_revision "svn://svn.openwrt.org/branches/$packages_dir"
				cd ..
			fi
			cd $packages_dir
			packages_revision=$(svn info | grep Revision | cut -d ' ' -f 2)
			cd ../
		fi
	;;
	*)
		packages_dir='packages_10.03.2'
		if [ -d $packages_dir ] ; then
			echo "update $packages_dir svn up"
			cd $packages_dir
			rm -rf $(svn status)
			if [ -z $packages_revision ] ; then
				svn up  || exit 0
			else
				svn sw -r $packages_revision "svn://svn.openwrt.org/openwrt/branches/$packages_dir"  || exit 0
			fi
			packages_revision=$(svn info | grep Revision | cut -d ' ' -f 2)
			cd ../
		else
			echo "create $packages_dir svn co"
			svn co "svn://svn.openwrt.org/openwrt/branches/$packages_dir"
			if [ -z $packages_revision ] ; then
				svn co "svn://svn.openwrt.org/openwrt/branches/$packages_dir"
			else
				svn co "svn://svn.openwrt.org/openwrt/branches/$packages_dir"
				cd $packages_dir
				svn sw -r $packages_revision "svn://svn.openwrt.org/openwrt/branches/$packages_dir"
				cd ..
			fi
			cd $packages_dir
			packages_revision=$(svn info | grep Revision | cut -d ' ' -f 2)
			cd ../
		fi
	;;
esac

echo "OpenWrt $packages_dir Revision: $packages_revision" >> VERSION.txt
case $verm in
	trunk) 
		PACKAGESPATCHES="$PACKAGESPATCHES trunk-radvd-ifconfig.patch"
		PACKAGESPATCHES="$PACKAGESPATCHES trunk-olsrd.init_6and4-patches.patch"
		PACKAGESRPATCHES="$PACKAGESRPATCHES packages-r31282.patch"
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

#update and patch repos
if [ -d packages-pberg ] ; then
	echo "update packages-pberg git pull"
	cd packages-pberg
	git reset --hard
	git pull origin master || exit 0
	[ -z $packages_pberg_revision ] || git checkout $packages_pberg_revision || exit 0
	packages_pberg_revision=$(git rev-parse HEAD)
	cd ../
else
	echo "create packages-pberg git clone"
	git clone git://github.com/freifunk/packages-pberg.git || exit 0
	cd packages-pberg
	[ -z $packages_pberg_revision ] || git checkout $packages_pberg_revision || exit 0
	packages_pberg_revision=$(git rev-parse HEAD)
	cd ../
fi
echo "packages-pberg Revision: $packages_pberg_revision" >> VERSION.txt

if [ -d piratenfreifunk-packages ] ; then
	echo "update piratenfreifunk-packages manual git pull"
	cd piratenfreifunk-packages
	git reset --hard
	git pull origin master || exit 0
	[ -z $piratenfreifunk_packages_revision ] || git checkout $piratenfreifunk_packages_revision || exit 0
	piratenfreifunk_packages_revision=$(git rev-parse HEAD)
	cd ../
else
	echo "create piratenfreifunk-packages git clone"
	git clone git://github.com/freifunk/piratenfreifunk-packages.git || exit 0
	cd piratenfreifunk-packages
	[ -z $piratenfreifunk_packages_revision ] || git checkout $piratenfreifunk_packages_revision || exit 0
	piratenfreifunk_packages_revision=$(git rev-parse HEAD)
	cd ../
fi
echo "piratenfreifunk-packages Revision: $piratenfreifunk_packages_revision" >> VERSION.txt

if [ -d luci-master ] ; then
	echo "update luci-master git pull"
	cd luci-master
	git add .
	rmf="$(git diff --cached | grep 'diff --git a' | cut -d ' ' -f 3 | cut -b 3-)"
	[ -z "$rm" ] || rm "$rmf"
	git reset --hard
	git checkout master .
	git remote rm origin
	git remote add origin git@github.com:freifunk/luci.git
	git pull -u origin master || exit 0
	[ -z $luci_version ]  || git checkout "$luci_version"  || exit 0
	[ -z $luci_revision ] || git checkout "$luci_revision" || exit 0
	luci_revision=$(git rev-parse HEAD)
	cd ../
else
	echo "create HEAD master"
	git clone git@github.com:freifunk/luci.git luci-master || exit 0
	cd luci-master
	[ -z $luci_version ]  || git checkout "$luci_version"  || exit 0
	[ -z $luci_revision ] || git checkout "$luci_revision" || exit 0
	luci_revision=$(git rev-parse HEAD)
	cd ../
fi

echo "LUCI Branch: luci-master" >> VERSION.txt
echo "LUCI Revision: $luci_revision" >> VERSION.txt

cd luci-master
LUCIPATCHES="$LUCIPATCHES luci-profile_muenster.patch"
LUCIPATCHES="$LUCIPATCHES luci-profile_cottbus.patch"
LUCIPATCHES="$LUCIPATCHES luci-profile_ndb.patch"
LUCIPATCHES="$LUCIPATCHES luci-profile_ffwtal.patch"
LUCIPATCHES="$LUCIPATCHES luci-profile_berlin.patch"
LUCIPATCHES="$LUCIPATCHES luci-profile_bno.patch"
LUCIPATCHES="$LUCIPATCHES luci-profile_pberg.patch"
LUCIPATCHES="$LUCIPATCHES luci-app-olsr-use-admin-mini.patch"
LUCIPATCHES="$LUCIPATCHES luci-modfreifunk-use-admin-mini.patch"
LUCIPATCHES="$LUCIPATCHES luci-modfreifunk-use-admin-mini-status.patch"
LUCIPATCHES="$LUCIPATCHES luci-modfreifunk-use-admin-mini-makefile.patch"
LUCIPATCHES="$LUCIPATCHES luci-admin-mini-sysupgrade.patch"
LUCIPATCHES="$LUCIPATCHES luci-freifunk-common-neighb6.patch"
LUCIPATCHES="$LUCIPATCHES luci-admin-mini-splash.patch"
LUCIPATCHES="$LUCIPATCHES luci-admin-mini-index.patch"
LUCIPATCHES="$LUCIPATCHES luci-admin-mini-backup-style.patch"
LUCIPATCHES="$LUCIPATCHES luci-admin-mini-sshkeys.patch"
#LUCIPATCHES="$LUCIPATCHES luci-sys-routes6.patch"
LUCIPATCHES="$LUCIPATCHES luci-freifunk_radvd_gvpn.patch"
LUCIPATCHES="$LUCIPATCHES luci-freifunk-common.patch"
LUCIPATCHES="$LUCIPATCHES luci-app-splash-css.patch"
LUCIPATCHES="$LUCIPATCHES luci-modfreifunk-migrate.patch"
LUCIPATCHES="$LUCIPATCHES luci-gwcheck-makefile.patch"
LUCIPATCHES="$LUCIPATCHES luci-theme-bootstrap.patch"
LUCIPATCHES="$LUCIPATCHES luci-olsr-view.patch"
LUCIPATCHES="$LUCIPATCHES luci-olsr-service-view.patch"
LUCIPATCHES="$LUCIPATCHES luci-splash-mark.patch"
LUCIPATCHES="$LUCIPATCHES luci-admin-mini-dhcp.patch"
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
	mkdir -p	$wwwdir/$verm/$ver/$board/packages
	rsync -lptgoD bin/*/packages/*	$wwwdir/$verm/$ver/$board/packages
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
	rm -f $(svn status)
	case $verm in
		trunk) 
			#svn co svn://svn.openwrt.org/openwrt/trunk ./  || exit 0
			rsync -a ../../openwrt-trunk/* ./
			;;
		*)
			#svn co svn://svn.openwrt.org/openwrt/branches/$verm ./ || exit 0
			rsync -a ../../openwrt-$verm/* ./
			;;
	esac
	openwrt_revision=$(svn info | grep Revision | cut -d ' ' -f 2)
	cp ../../VERSION.txt VERSION.txt
	echo "OpenWrt Branch: $verm" >> VERSION.txt
	echo "OpenWrt Revision: $openwrt_revision" >> VERSION.txt
	echo "OpenWrt Board: $board" >> VERSION.txt
	cat ../../ff-control/patches/ascii_backfire.txt >> package/base-files/files/etc/banner
	cp VERSION.txt package/base-files/files/etc
	echo "URL http://$servername/$verm/$ver-timestamp/$timestamp/$board on $(hostname)">> package/base-files/files/etc/banner

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
			case $board in
				x86_kvm_guest)
					PATCHES="$PATCHES kvm-default-config.patch"
				;;
			esac
			make_options_ver="CONFIG_VERSION_REPO=\"http://$servername/$verm/$ver-timestamp/$timestamp/$board/packages\""
			;;
		*)
			sed -i -e 's/\(DISTRIB_DESCRIPTION=".*\)"/\1 (r'$openwrt_revision') build date: '$timestamp'"/' package/base-files/files/etc/openwrt_release
			#sed -i -e "s,downloads\.openwrt\.org.*,$servername/$verm/$ver-timestamp/$timestamp/$board/packages," package/opkg/files/opkg.conf
			make_options_ver="CONFIG_VERSION_REPO=\"http://$servername/$verm/$ver-timestamp/$timestamp/$board/packages\""
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
				;;
				atheros)
					PATCHES="$PATCHES atheros-disable-pci-usb.patch" #no trunk
					PATCHES="$PATCHES whr-hp-ag108-sysupgrade.patch" #no trunk
				;;
				ixp4xx)
					PATCHES="$PATCHES  target-ixp4xx-avila-sysupgrade.patch" #no trunk
				;;
				brcm-2.4)
					PATCHES="$PATCHES brcm-2.4-reboot-fix.patch" #no trunk
				;;
				x86_kvm_guest)
#					PATCHES="$PATCHES x86-virtio-usb-boot.patch"
					PATCHES="$PATCHES add-qcow-images.patch"
				;;
#				x86)
#					PATCHES="$PATCHES x86-usb-boot.patch"
#				;;
			esac
			;;
	esac
	PATCHES="$PATCHES busybox-iproute2.patch"
	PATCHES="$PATCHES base-system.patch"
	PATCHES="$PATCHES package-crda-regulatory-pberg.patch"
	#PATCHES="$PATCHES package-mac80211-dir300.patch"
	#PATCHES="$PATCHES package-iwinfo-1.patch" #no trunk
	#PATCHES="$PATCHES package-iwinfo-2.patch" #no trunk
	#PATCHES="$PATCHES package-iwinfo-3.patch" #no trunk
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
		brcm-2.4)
			rm -f bin/*/*
			echo "copy config ../../ff-control/configs/$verm-$board.config .config"
			cp  ../../ff-control/configs/$verm-$board.config .config
			genconfig "$make_options_ver"
			genconfig "$make_options"
			genconfig "$make_options_2_4"
			genconfig "$make_min_options"
			${MAKE} V=99 world || build_fail=1
			rsync_web minimal
			rm -f bin/*/*
			echo "copy config ../../ff-control/configs/$verm-$board.config .config"
			cp  ../../ff-control/configs/$verm-$board.config .config
			genconfig "$make_options_ver"
			genconfig "$make_options"
			genconfig "$make_options_2_4"
			${MAKE} V=99 world || build_fail=1
			rsync_web
			rm -f bin/*/*
			echo "copy config ../../ff-control/configs/$verm-$board.config .config"
			cp  ../../ff-control/configs/$verm-$board.config .config
			genconfig "$make_options_ver"
			genconfig "$make_options"
			genconfig "$make_options_2_4"
			genconfig "$make_pi_options"
			${MAKE} V=99 world || build_fail=1
			rsync_web "piraten"
		;;
		atheros|brcm47xx|brcm63xx)
			rm -f bin/*/*
			echo "copy config ../../ff-control/configs/$verm-$board.config .config"
			cp  ../../ff-control/configs/$verm-$board.config .config
			genconfig "$make_options_ver"
			genconfig "$make_options"
			genconfig "$make_min_options"
			genconfig "$make_min_options_2_6"
			${MAKE} V=99 world || build_fail=1
			rsync_web minimal
			rm -f bin/*/*
			echo "copy config ../../ff-control/configs/$verm-$board.config .config"
			cp  ../../ff-control/configs/$verm-$board.config .config
			genconfig "$make_options_ver"
			genconfig "$make_options"
			genconfig "$make_options_2_6"
			${MAKE} V=99 world || build_fail=1
			rsync_web
			rm -f bin/*/*
			echo "copy config ../../ff-control/configs/$verm-$board.config .config"
			cp  ../../ff-control/configs/$verm-$board.config .config
			genconfig "$make_options_ver"
			genconfig "$make_options"
			genconfig "$make_options_2_6"
			genconfig "$make_pi_options"
			${MAKE} V=99 world || build_fail=1
			rsync_web "piraten"
		;;
		*)
			rm -f bin/*/*
			echo "copy config ../../ff-control/configs/$verm-$board.config .config"
			cp  ../../ff-control/configs/$verm-$board.config .config
			genconfig "$make_options_ver"
			genconfig "$make_options"
			genconfig "$make_min_options"
			genconfig "$make_min_options_2_6"
			${MAKE} V=99 world || build_fail=1
			rsync_web minimal
			rm -f bin/*/*
			echo "copy config ../../ff-control/configs/$verm-$board.config .config"
			cp  ../../ff-control/configs/$verm-$board.config .config
			genconfig "$make_options_ver"
			genconfig "$make_options"
			genconfig "$make_options_2_6"
			${MAKE} V=99 world || build_fail=1
			rsync_web
			rm -f bin/*/*
			echo "copy config ../../ff-control/configs/$verm-$board.config .config"
			cp  ../../ff-control/configs/$verm-$board.config .config
			genconfig "$make_options_ver"
			genconfig "$make_options"
			genconfig "$make_usb_options"
			genconfig "$make_options_2_6"
			genconfig "$make_big_options"
			${MAKE} V=99 world || build_fail=1
			rsync_web "full"
			rm -f bin/*/*
			echo "copy config ../../ff-control/configs/$verm-$board.config .config"
			cp  ../../ff-control/configs/$verm-$board.config .config
			genconfig "$make_options_ver"
			genconfig "$make_options"
			genconfig "$make_options_2_6"
			genconfig "$make_pi_options"
			${MAKE} V=99 world || build_fail=1
			rsync_web "piraten"
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
#	(
#		rsync -av --delete "$wwwdir/$verm/$ver-timestamp/$timestamp" "openwrt@pberg.freifunk.net:$wwwdir/$verm/$ver-timestamp/"
#		ssh openwrt@pberg.freifunk.net "rsync -av --delete $wwwdir/$verm/$ver-timestamp/$timestamp/ $wwwdir/$verm/$ver/"
		#if [ "$ca_user" != "" -a "$ca_pw" != "" ] ; then
		#	curl -u "$ca_user:$ca_pw" -d status="$tags New Build #$verm #$ver for #$board Boards http://$servername/$verm/$ver/$board" http://identi.ca/api/statuses/update.xml >/dev/null
		#fi
#	)&
	#&
	#pid=$!
	#echo $pid > update-build-$verm-$board.pid
done
echo "rsync -av --delete $wwwdir/$verm/$ver-timestamp/$timestamp openwrt@pberg.freifunk.net:$wwwdir/$verm/$ver-timestamp/"
echo "ssh openwrt@pberg.freifunk.net 'rsync -av --delete $wwwdir/$verm/$ver-timestamp/$timestamp/ $wwwdir/$verm/$ver/'"

