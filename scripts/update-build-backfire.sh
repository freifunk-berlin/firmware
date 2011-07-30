#!/bin/sh

. ./config

for board in $boards ; do
	[ -f "update-build-$verm-$board.lock" ] && echo "build $verm-$board are running. if not do rm update-build-$verm-$board.lock" && exit 0
done

timestamp=`date "+%F_%H-%M"`
echo $timestamp >timestamp
date +"%Y/%m/%d %H:%M">VERSION.txt

if [ -d yaffmap-agent ] ; then
	echo "update yaffmap-agent git pull"
	cd yaffmap-agent
	git pull || exit 0
	cd ../
else
	echo "create yaffmap-agent git clone"
	git clone git://github.com/wurststulle/yaffmap-agent.git || exit 0
	#git clone git://github.com/stargieg/yaffmap-agent.git || exit 0
fi

if [ -d luci-app-bulletin-node ] ; then
	echo "update luci-app-bulletin-node git pull"
	cd luci-app-bulletin-node
	git pull || exit 0
	cd ../
else
	echo "create luci-app-bulletin-node git clone"
	#git clone git://github.com/rhotep/luci-app-bulletin-node.git || exit 0
	git clone git://github.com/stargieg/luci-app-bulletin-node.git || exit 0
fi


if [ -d packages ] ; then
	echo "update packages svn up"
	cd packages
	rm -rf $(svn status)
	if [ -z $packages_revision ] ; then
		svn up  || exit 0
	else
		#svn sw -r $packages_revision 'svn://svn.openwrt.org/openwrt/packages' || exit 0
		svn sw -r $packages_revision 'svn://svn.openwrt.org/openwrt/branches/packages_10.03.1'  || exit 0
	fi
	cd ../
else
	echo "create packages svn co"
	#svn co 'svn://svn.openwrt.org/openwrt/packages packages'
	svn co 'svn://svn.openwrt.org/openwrt/branches/packages_10.03.1'
	if [ -z $packages_revision ] ; then
		#svn co 'svn://svn.openwrt.org/openwrt/packages packages' || exit 0
		svn co 'svn://svn.openwrt.org/openwrt/branches/packages_10.03.1'
	else
		#svn co 'svn://svn.openwrt.org/openwrt/packages packages' || exit 0
		svn co 'svn://svn.openwrt.org/openwrt/branches/packages_10.03.1'
		cd packages
		#svn sw -r $packages_revision 'svn://svn.openwrt.org/openwrt/packages' || exit 0
		svn sw -r $packages_revision 'svn://svn.openwrt.org/openwrt/branches/packages_10.03.1'
		cd ..
	fi
fi

cd packages
packages_revision=$(svn info | grep Revision | cut -d ' ' -f 2)
echo "OpenWrt Packages Revision: $packages_revision" >> ../VERSION.txt
PACKAGESPATCHES="$PACKAGESPATCHES radvd-ifconfig.patch"
PACKAGESPATCHES="$PACKAGESPATCHES olsrd.init_6and4-patches.patch"
PACKAGESPATCHES="$PACKAGESPATCHES package-collectd.patch"
PACKAGESPATCHES="$PACKAGESPATCHES olsrd.config-rm-wlan-patches.patch"
PACKAGESRPATCHES="$PACKAGESRPATCHES packages-r27157.patch"

for i in $PACKAGESPATCHES ; do
	pparm='-p0'
	#echo "Patch: $i"
	patch $pparm < ../ff-control/patches/$i || exit 0
done
for i in $PACKAGESRPATCHES ; do
	pparm='-p0 -R'
	#echo "Patch: $i"
	patch $pparm < ../ff-control/patches/$i || exit 0
done
#rm -rf libs/mysql
cd ..

#update and patch repos
if [ -d packages-pberg ] ; then
	echo "update packages-pberg git pull"
	cd packages-pberg
	git pull || exit 0
	cd ../
else
	echo "create packages-pberg git clone"
	git clone git://github.com/stargieg/packages-pberg.git || exit 0
fi

if [ -d piratenfreifunk-packages ] ; then
	echo "update piratenfreifunk-packages manual git pull"
	cd piratenfreifunk-packages
	git pull || exit 0
	cd ../
else
	echo "create piratenfreifunk-packages git clone"
	git clone git://github.com/basicinside/piratenfreifunk-packages.git || exit 0
fi

if [ -d luci-master ] ; then
	echo "update luci-master git pull"
	cd luci-master
	git checkout HEAD .
	git add .
	rmf="$(git diff --cached | grep 'diff --git a' | cut -d ' ' -f 3 | cut -b 3-)"
	[ -z "$rm" ] || rm "$rmf"
	git reset --hard
	git pull git://nbd.name/luci.git || exit 0
	[ -z $luci_revision ] || git checkout $luci_revision || exit 0
	cd ../
else
	echo "create HEAD master"
	git clone git://nbd.name/luci.git luci-master || exit 0
	cd luci-master
	git checkout origin/master || exit 0
	cd ../
fi

echo "LUCI Branch: luci-master" >> VERSION.txt

cd luci-master
luci_revision=$(git rev-parse HEAD)
echo "LUCI Revision: $luci_revision" >> ../VERSION.txt
LUCIPATCHES="$LUCIPATCHES luci-profile_muenster.patch"
LUCIPATCHES="$LUCIPATCHES luci-profile_cottbus.patch"
LUCIPATCHES="$LUCIPATCHES luci-profile_ndb.patch"
LUCIPATCHES="$LUCIPATCHES luci-profile_ffwtal.patch"
LUCIPATCHES="$LUCIPATCHES luci-profile_berlin.patch"
LUCIPATCHES="$LUCIPATCHES luci-profile_bno.patch"
LUCIPATCHES="$LUCIPATCHES luci-profile_pberg.patch"
LUCIPATCHES="$LUCIPATCHES luci-app-olsr-use-admin-mini.patch"
LUCIPATCHES="$LUCIPATCHES luci-modfreifunk-use-admin-mini.patch"
LUCIPATCHES="$LUCIPATCHES luci-admin-mini-sysupgrade.patch"
LUCIPATCHES="$LUCIPATCHES luci-freifunk-firewall-natfix.patch"
LUCIPATCHES="$LUCIPATCHES luci-admin-mini-splash.patch"
LUCIPATCHES="$LUCIPATCHES luci-admin-mini-install-full.patch"
LUCIPATCHES="$LUCIPATCHES luci-admin-mini-backup-style.patch"
LUCIPATCHES="$LUCIPATCHES luci-admin-mini-sshkeys.patch"
LUCIPATCHES="$LUCIPATCHES luci-sys-routes6.patch"
LUCIPATCHES="$LUCIPATCHES luci-app-statistics-add-madwifi-olsr.patch"
LUCIPATCHES="$LUCIPATCHES luci-freifunk_radvd_gvpn.patch"
LUCIPATCHES="$LUCIPATCHES luci-app-splash-css.patch"
LUCIPATCHES="$LUCIPATCHES luci-modfreifunk-migrate.patch"
for i in $LUCIPATCHES ; do
	pparm='-p1'
	echo "Patch: $i"
	patch $pparm < ../ff-control/patches/$i || exit 0
done

rm -rf modules/freifunk/luasrc/controller/freifunk/remote_update.lua
rm -rf modules/freifunk/luasrc/view/freifunk/remote_update.htm

rm -rf $(find . | grep \.rej$)
rm -rf $(find . | grep \.orig$)
cd ..

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
	rm -rf ./tmp
#	rm -rf ./feeds/*
#	rm -rf ./feeds/*.tmp
#	rm -rf ./feeds/*.index
##	rm -rf ./package/feeds/*
	rm -rf ./bin
	rm -rf build_dir/*/*luci*
##	rm -rf build_dir/*/lua*
##	rm -rf dl/*luci*
	rm -rf build_dir/*/compat-wireless*
##	rm -rf $(find . | grep \.rej$)
##	rm -rf $(find . | grep \.orig$)
	rm -rf ./build_dir
	rm -rf ./staging_dir
	rm -rf ./files
	mkdir -p ./files
	rm -rf $(svn status)
	case $verm in
		trunk) 
			svn co svn://svn.openwrt.org/openwrt/trunk ./  || exit 0
			;;
		*)
			svn co svn://svn.openwrt.org/openwrt/branches/$verm ./ || exit 0
			;;
	esac
	if [ -z $openwrt_revision ] ; then
		svn up || exit 0
	else
		case $verm in
			trunk) 
				svn sw -r $openwrt_revision svn://svn.openwrt.org/openwrt/trunk || exit 0
				;;
			*)
				svn sw -r $openwrt_revision svn://svn.openwrt.org/openwrt/branches/$verm || exit 0
				;;
		esac
	fi
	openwrt_revision=$(svn info | grep Revision | cut -d ' ' -f 2)
	cp ../../VERSION.txt VERSION.txt
	echo "OpenWrt Branch: $verm" >> VERSION.txt
	echo "OpenWrt Revision: $openwrt_revision" >> VERSION.txt
	echo "OpenWrt Board: $board" >> VERSION.txt
	echo "Built $(head -n 1 ../../VERSION.txt) on $(hostname)">> package/base-files/files/etc/banner
	echo "URL http://$servername/$verm/$ver-timestamp/$timestamp/$board on $(hostname)">> package/base-files/files/etc/banner
	sed -i -e 's/\(DISTRIB_DESCRIPTION=".*\)"/\1 build date: '$timestamp'"/' package/base-files/files/etc/openwrt_release

	echo "Generate feeds.conf"
	>feeds.conf
	echo "src-link packages ../../../packages" >> feeds.conf
	echo "src-link packagespberg ../../../packages-pberg" >> feeds.conf
	echo "src-link piratenluci ../../../piratenfreifunk-packages" >> feeds.conf
	echo "src-link luci ../../../luci-master" >> feeds.conf
	#echo "src-link wgaugsburg ../../../wgaugsburg/packages" >> feeds.conf
	echo "src-link yaffmapagent ../../../yaffmap-agent" >> feeds.conf
	echo "src-link bulletin ../../../luci-app-bulletin-node" >> feeds.conf
	echo "openwrt feeds update"
	scripts/feeds update
	echo "openwrt feeds install"
	scripts/feeds install -a
	sed -i -e "s,downloads\.openwrt\.org.*,$servername/$verm/$ver-timestamp/$timestamp/$board/packages," package/opkg/files/opkg.conf
	PATCHES="$PATCHES base-passwd-admin.patch"
	PATCHES="$PATCHES base-system.patch"
	PATCHES="$PATCHES routerstation-bridge-wan-lan.patch"
	PATCHES="$PATCHES routerstation-pro-bridge-wan-lan.patch"
	PATCHES="$PATCHES brcm-2.4-reboot-fix.patch"
	#PATCHES="$PATCHES ar5312_flash_4MB_flash.patch"
	PATCHES="$PATCHES base-disable-ipv6-autoconf.patch"
	PATCHES="$PATCHES package-crda-regulatory-pberg.patch"
	#PATCHES="$PATCHES make-art-writeable.patch"
	#RPATCHES="$RPATCHES packages-r27821.patch"
	#RPATCHES="$RPATCHES packages-r27815.patch"
	cp ../../ff-control/patches/regulatory.bin.pberg dl/regulatory.bin.pberg
	for i in $PATCHES ; do
		pparm='-p0'
		echo "Patch: $i"
		patch $pparm < ../../ff-control/patches/$i || exit 0
	done
	for i in $RPATCHES ; do
		pparm='-p2 -R'
		# get patch with:
		# wget --no-check-certificate -O 'ff-control/patches/packages-r27821.patch' 'http://dev.openwrt.org/changeset/27821/branches/backfire/package?format=diff&new=27821'
		# wget --no-check-certificate -O 'ff-control/patches/packages-r27815.patch' 'http://dev.openwrt.org/changeset/27815/branches/backfire/package?format=diff&new=27815'
		echo "Patch: $i"
		patch $pparm < ../../ff-control/patches/$i || exit 0
	done
	cp "../../ff-control/patches/200-fix_ipv6_receiving_with_ipv4_socket.patch" "target/linux/brcm-2.4/patches"
	echo "copy config ../../ff-control/configs/$verm-$board.config .config"
	cp  ../../ff-control/configs/$verm-$board.config .config
#	cd package/firewall
#	svn co svn://svn.openwrt.org/openwrt/trunk/package/firewall
#	cd ../../
#	cd package
#	rm -rf mac80211
#	svn co svn://svn.openwrt.org/openwrt/trunk/package/mac80211
#	rm -rf iw
#	svn co svn://svn.openwrt.org/openwrt/trunk/package/iw
#	cd ../
#	cd package/mac80211
##	svn sw -r 26762 svn://svn.openwrt.org/openwrt/branches/backfire/package/mac80211
#	svn sw -r 26686 svn://svn.openwrt.org/openwrt/branches/backfire/package/mac80211
#	cd ../../
	mkdir -p ../../dl
	[ -h dl ] || ln -s ../../dl dl
	case $board in
		x86)
			nice -n 10 make V=99 world $make_options $make_big_options || ( rm update-build-$verm-$board.lock ; exit 1 )
		;;
		x86_kvm_guest)
			nice -n 10 make V=99 world $make_options $make_big_options || ( rm update-build-$verm-$board.lock ; exit 1 )
		;;
		ixp4xx)
			nice -n 10 make V=99 world $make_options $make_big_options || ( rm update-build-$verm-$board.lock ; exit 1 )
		;;
		rb532)
			nice -n 10 make V=99 world $make_options $make_big_options || ( rm update-build-$verm-$board.lock ; exit 1 )
		;;
		au1000)
			nice -n 10 make V=99 world $make_options $make_big_options || ( rm update-build-$verm-$board.lock ; exit 1 )
		;;
		ar71xx)
			nice -n 10 make V=99 world $make_options || ( rm update-build-$verm-$board.lock ; exit 1 )
			nice -n 10 make V=99 world $make_options $make_big_options CONFIG_PACKAGE_kmod-madwifi=y  || ( rm update-build-$verm-$board.lock ; exit 1 )
		;;
		*)
			nice -n 10 make V=99 world $make_options || ( rm update-build-$verm-$board.lock ; exit 1 )
		;;
	esac
#	cp bin/$board/OpenWrt-ImageBuilder-$board-for-*.tar.bz2 ../
	cp build_dir/target-$arch*/root-*/usr/lib/opkg/status ../opkg-$board.status
	mkdir -p 			$wwwdir/$verm/$ver-timestamp/$timestamp/$board
	rsync -a --delete bin/*/ 	$wwwdir/$verm/$ver-timestamp/$timestamp/$board
	cp VERSION.txt		 	$wwwdir/$verm/$ver-timestamp/$timestamp/$board
	cp .config 			$wwwdir/$verm/$ver-timestamp/$timestamp/$board/dot-config
	mkdir -p 			$wwwdir/$verm/$ver/$board
	rsync -a --delete bin/*/ 	$wwwdir/$verm/$ver/$board
	cp VERSION.txt			$wwwdir/$verm/$ver/$board
	cp .config 			$wwwdir/$verm/$ver/$board/dot-config
	cd ../../
	rm update-build-$verm-$board.lock
	if [ "$ca_user" != "" -a "$ca_pw" != "" ] ; then
		curl -u "$ca_user:$ca_pw" -d status="$tags New Build #$verm #$ver for #$board Boards http://$servername/$verm/$ver/$board" http://identi.ca/api/statuses/update.xml >/dev/null
	fi
	) >update-build-$verm-$board.log 2>&1
	#&
	#pid=$!
	#echo $pid > update-build-$verm-$board.pid
	cp update-build-$verm-$board.log $wwwdir/$verm/$ver-timestamp/$timestamp/$board/
	cp update-build-$verm-$board.log $wwwdir/$verm/$ver/$board/
done

