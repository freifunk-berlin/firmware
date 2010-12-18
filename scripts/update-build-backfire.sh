#!/bin/sh

. ./config

for board in $boards ; do
	[ -f "update-build-$verm-$board.lock" ] && echo "build $verm-$board are running. if not do rm update-build-$verm-$board.lock" && exit 0
done

timestamp=`date "+%F_%H-%M"`
echo $timestamp >timestamp
date +"%Y/%m/%d %H:%M">VERSION.txt

if [ -d packages ] ; then
	echo "update packages svn up"
	cd packages
	rm -rf $(svn status)
	if [ -z $packages_revision ] ; then
		svn up
	else
		svn sw -r $packages_revision svn://svn.openwrt.org/openwrt/packages
	fi
	cd ../
else
	echo "create packages svn co"
	svn co svn://svn.openwrt.org/openwrt/packages packages
	if [ -z $packages_revision ] ; then
		svn co svn://svn.openwrt.org/openwrt/packages packages
	else
		svn co svn://svn.openwrt.org/openwrt/packages packages
		cd packages
		svn sw -r $packages_revision svn://svn.openwrt.org/openwrt/packages
		cd ..
	fi
fi
cd packages
packages_revision=$(svn info | grep Revision | cut -d ' ' -f 2)
echo "OpenWrt Packages Revision: $packages_revision" >> ../VERSION.txt
PACKAGESPATCHES="$PACKAGESPATCHES radvd-ifconfig.patch"
for i in $PACKAGESPATCHES ; do
	pparm='-p0'
	echo "Patch: $i"
	patch $pparm < ../ff-control/patches/$i
done
cd ..

#update and patch repos
if [ -d packages-pberg ] ; then
	echo "update packages-pberg git pull"
	cd packages-pberg
	git pull
	cd ../
else
	echo "create packages-pberg git clone"
	git clone git://github.com/stargieg/packages-pberg.git
fi

if [ -d piratenfreifunk-packages ] ; then
	echo "update piratenfreifunk-packages manual git pull"
	cd piratenfreifunk-packages
	git pull
	cd ../
else
	echo "create piratenfreifunk-packages git clone"
	git clone git://github.com/basicinside/piratenfreifunk-packages.git
fi

if [ -d luci-0.9 ] ; then
	echo "update luci-0.9 svn up"
	cd luci-0.9
	git checkout HEAD .
	git add .
	rm $(git diff --cached | grep 'diff --git a' | cut -d ' ' -f 3 | cut -b 3-)
	git reset
	git pull
	#rm -rf $(svn status)
	#if [ -z $luci_revision ] ; then
	#	svn up
	#else
	#	svn sw -r $luci_revision http://svn.luci.subsignal.org/luci/branches/luci-0.9
	#fi
	cd ../
else
	echo "create luci-0.9 svn co"
	#svn co http://svn.luci.subsignal.org/luci/branches/luci-0.9 luci-0.9
	git clone git://nbd.name/luci.git luci-0.9
	cd luci-0.9
	git checkout origin/luci-0.9
	cd ../
	#if [ -z $luci_revision ] ; then
	#	svn co http://svn.luci.subsignal.org/luci/branches/luci-0.9 luci-0.9
	#else
	#	svn co http://svn.luci.subsignal.org/luci/branches/luci-0.9 luci-0.9
	#	cd luci-0.9
	#	svn sw -r $luci_revision http://svn.luci.subsignal.org/luci/branches/luci-0.9
	#	cd ..
	#fi
fi
echo "LUCI Branch: luci-0.9" >> VERSION.txt

cd luci-0.9
luci_revision=$(svn info | grep Revision | cut -d ' ' -f 2)
echo "LUCI Revision: $luci_revision" >> ../VERSION.txt
LUCIPATCHES="$LUCIPATCHES luci-olsr-ipv6.patch"
LUCIPATCHES="$LUCIPATCHES luci-olsrd-dnsmasq-addnhosts-list.patch"
LUCIPATCHES="$LUCIPATCHES luci-olsrd-lqmult-list.patch"
LUCIPATCHES="$LUCIPATCHES luci-olsrd-p2p.patch"
LUCIPATCHES="$LUCIPATCHES luci-freifunk.patch"
LUCIPATCHES="$LUCIPATCHES freifunk-BergischesLand.patch"
LUCIPATCHES="$LUCIPATCHES freifunk-dresden.patch"
LUCIPATCHES="$LUCIPATCHES freifunk-neuss.patch"
LUCIPATCHES="$LUCIPATCHES freifunk-muenster.patch"
LUCIPATCHES="$LUCIPATCHES freifunk-cottbus.patch"
LUCIPATCHES="$LUCIPATCHES freifunk-pberg.patch"
LUCIPATCHES="$LUCIPATCHES luci-map-update.patch"
LUCIPATCHES="$LUCIPATCHES luci-freifunk_berlin.patch"
LUCIPATCHES="$LUCIPATCHES luci-remove-remoteupdate.patch"
LUCIPATCHES="$LUCIPATCHES luci-ipv6-status.patch"
for i in $LUCIPATCHES ; do
	pparm='-p0'
	echo "Patch: $i"
	patch $pparm < ../ff-control/patches/$i
done
rm modules/freifunk/luasrc/controller/freifunk/remote_update.lua
rm modules/freifunk/luasrc/view/freifunk/remote_update.htm

chmod +x applications/luci-olsr/root/etc/init.d/luci_olsr
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
	rm -rf ./feeds/*.tmp
	rm -rf ./feeds/*.index
#	rm -rf ./package/feeds/*
	rm -rf ./bin
	rm -rf build_dir/*/*luci*
#	rm -rf build_dir/*/lua*
#	rm -rf dl/*luci*
#	rm -rf build_dir/*/compat-wireless*
	rm -rf $(find . | grep \.rej$)
	rm -rf $(find . | grep \.orig$)
#	rm -rf ./build_dir
#	rm -rf ./staging_dir
	rm -rf ./files
	mkdir -p ./files
	rm -rf $(svn status)
	#openwrt_revision="r23025"
	svn co svn://svn.openwrt.org/openwrt/branches/$verm ./
	if [ -z $openwrt_revision ] ; then
		svn up
	else
		svn sw -r $openwrt_revision svn://svn.openwrt.org/openwrt/branches/$verm
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
	echo "src-link luci ../../../luci-0.9" >> feeds.conf

	echo "openwrt feeds update"
	scripts/feeds update
	echo "openwrt feeds install"
	scripts/feeds install -a
	scripts/feeds uninstall libxslt
	scripts/feeds install -p packagespberg libxslt
	scripts/feeds uninstall xsltproc
	scripts/feeds install -p packagespberg xsltproc
	scripts/feeds uninstall motion
	scripts/feeds install -p packagespberg motion
	scripts/feeds uninstall olsrd-luci
	scripts/feeds install -p packagespberg olsrd-luci
# 	rm -rf package/uhttpd
#	scripts/feeds install -p packagespberg uhttpd
	sed -i -e "s/downloads\.openwrt\.org.*/$servername\/$verm\/$ver-timestamp\/$timestamp\/$board\/packages/" package/opkg/files/opkg.conf
	# enable hart reboot via echo "b" >/proc/sys/kernel/sysrq
	# kernel 2.4 sysrq is enable by default
#	sed -i -e 's/.*\(CONFIG_MAGIC_SYSRQ\).*/\1=y/' target/linux/generic-2.6/config-2.6.30
#	sed -i -e 's/.*\(CONFIG_MAGIC_SYSRQ\).*/\1=y/' target/linux/generic-2.6/config-2.6.32
#	sed -i -e 's/.*\(CONFIG_IDEDISK_MULTI_MODE\).*/\1=y/' target/linux/$board/config-default
#	sed -i -e 's/.*\(CONFIG_BLK_DEV_PIIX\).*/\1=y/' target/linux/$board/config-default
#	echo "CONFIG_PCIEAER=y" >> target/linux/$board/config-default
#	sed -i -e 's/.*\(CONFIG_PCIEPORTBUS\).*/\1=y/' target/linux/$board/config-default
#	sed -i -e 's/.*\(CONFIG_PCI_MSI\).*/\1=y/' target/linux/$board/config-default
#	sed -i -e 's/.*\(CONFIG_kmod-e1000\).*/\1=m/' target/linux/$board/config-default
#	echo "CONFIG_E1000_NAPI=n" >> target/linux/$board/config-default
#	echo "CONFIG_E1000_DISABLE_PACKET_SPLIT=n" >> target/linux/$board/config-default
#	sed -i -e 's/.*\(CONFIG_kmod-e1000e\).*/\1=m/' target/linux/$board/config-default
#	sed -i -e 's/.*\(CONFIG_kmod-igb\).*/\1=m/' target/linux/$board/config-default
#	sed -i -e 's/.*\(CONFIG_kmod-8139too\).*/\1=m/' target/linux/$board/config-default
#	echo "CONFIG_8139TOO_PIO=y" >> target/linux/$board/config-default
#	echo "CONFIG_8139TOO_TUNE_TWISTER=n" >> target/linux/$board/config-default
#	echo "CONFIG_8139TOO_8129=y" >> target/linux/$board/config-default
#	echo "CONFIG_8139_OLD_RX_RESET=n" >> target/linux/$board/config-default
######################FEAUTURE#################################################################
#	echo "CONFIG_SMP=y" >> target/linux/$board/generic/config-default
#	echo "CONFIG_X86_BIGSMP=y" >> target/linux/$board/generic/config-default
#	echo "CONFIG_X86_HT=y" >> target/linux/$board/generic/config-default
#	echo "CONFIG_NR_CPUS=32" >> target/linux/$board/generic/config-default
#	echo "CONFIG_SCHED_SMT=y" >> target/linux/$board/generic/config-default
#	echo "CONFIG_SCHED_MC=y" >> target/linux/$board/generic/config-default
###############################################################################################
#	PATCHES="$PATCHES mac80211-adhoc.patch"
#	PATCHES="$PATCHES wl0-to-wlan0.patch"
	PATCHES="$PATCHES base-passwd-admin.patch"
	PATCHES="$PATCHES base-system.patch"
	PATCHES="$PATCHES ipkg-utils-fast-zip.patch"
	PATCHES="$PATCHES routerstation-bridge-wan-lan.patch"
	for i in $PATCHES ; do
		pparm='-p0'
		echo "Patch: $i"
		patch $pparm < ../../ff-control/patches/$i
	done
	cp "../../ff-control/patches/200-fix_ipv6_receiving_with_ipv4_socket.patch" "target/linux/brcm-2.4/patches"
	echo "copy config ../../ff-control/configs/$verm-$board.config .config"
	cp  ../../ff-control/configs/$verm-$board.config .config
	mkdir -p ../../dl
	[ -h dl ] || ln -s ../../dl dl
	time nice -n 10 make V=99 world $make_options || ( rm update-build-$verm-$board.lock ; exit 1 )
	cp bin/$board/OpenWrt-ImageBuilder-$board-for-*.tar.bz2 ../
	cp build_dir/target-$arch*/root-$board/usr/lib/opkg/status ../opkg-$board.status

	mkdir -p 						$wwwdir/$verm/$ver-timestamp/$timestamp/$board
	rsync -a --delete bin/$board/ 	$wwwdir/$verm/$ver-timestamp/$timestamp/$board
	cp VERSION.txt		 			$wwwdir/$verm/$ver-timestamp/$timestamp/$board
	cp .config 						$wwwdir/$verm/$ver-timestamp/$timestamp/$board/dot-config
	mkdir -p 						$wwwdir/$verm/$ver/$board
	rsync -a --delete bin/$board/ 	$wwwdir/$verm/$ver/$board
	cp VERSION.txt					$wwwdir/$verm/$ver/$board
	cp .config 						$wwwdir/$verm/$ver/$board/dot-config
	case $board in
		ar71xx)
			make V=99 world $make_options CONFIG_PACKAGE_kmod-madwifi=y
			cp bin/$board/openwrt-ar71xx-ubnt-rs* $wwwdir/$verm/$ver/$board
		;;
	esac
	cd ../../
	rm update-build-$verm-$board.lock
	) >update-build-$verm-$board.log 2>&1 
	#&
	#pid=$!
	#echo $pid > update-build-$verm-$board.pid
	cp update-build-$verm-$board.log $wwwdir/$verm/$ver-timestamp/$timestamp/$board/
	cp update-build-$verm-$board.log $wwwdir/$verm/$ver/$board/
done
