#!/bin/sh

. ./config

ROUTING_PATCHES=""
ROUTING_PATCHES="$ROUTING_PATCHES routing-olsrd-json-bind-v6-only.patch"
ROUTING_PATCHES="$ROUTING_PATCHES routing-alfred-copy-gpsd.patch"
#ROUTING_PATCHES="$ROUTING_PATCHES routing-alfred-hosts.patch"
ROUTING_PATCHES="$ROUTING_PATCHES routing-nat46-gz.patch"

PACKAGES_PATCHES=""
case $verm in
	trunk)
		PACKAGES_PATCHES="$PACKAGES_PATCHES trunk-radvd-ifconfig.patch"
		PACKAGES_PATCHES="$PACKAGES_PATCHES package-pthsem-disable-eglibc-dep.patch"
		;;
	barrier_breaker)
		PACKAGES_PATCHES="$PACKAGES_PATCHES trunk-radvd-ifconfig.patch"
		PACKAGES_PATCHES="$PACKAGES_PATCHES package-pthsem-disable-eglibc-dep.patch"
		;;
	attitude_adjustment)
		#This Patch btctl-2014.0 is not needed for BB
		ROUTING_PATCHES="$ROUTING_PATCHES routing-batman-adv-btctl-2014.0.patch"
		PACKAGES_PATCHES="$PACKAGES_PATCHES trunk-radvd-ifconfig.patch"
		PACKAGES_PATCHES="$PACKAGES_PATCHES package-openvpn-backport-2.3.patch"
		PACKAGES_PATCHES="$PACKAGES_PATCHES package-openvpn-comp_lzo-value.patch"
		PACKAGES_PATCHES="$PACKAGES_PATCHES package-pthsem-disable-eglibc-dep.patch"
		PACKAGES_PATCHES="$PACKAGES_PATCHES package-pthsem-chk-linux-3.patch"
		PACKAGES_PATCHES="$PACKAGES_PATCHES package-nagios-plugins.patch"
		PACKAGES_PATCHES="$PACKAGES_PATCHES package-net-snmp.patch"
		PACKAGES_PATCHES="$PACKAGES_PATCHES package-argp-standalone.patch"
		;;
esac

LUCI_PATCHES=""
LUCI_PATCHES="$LUCI_PATCHES luci-olsr-controller.patch"
LUCI_PATCHES="$LUCI_PATCHES luci-modfreifunk-use-admin-mini-status.patch"
LUCI_PATCHES="$LUCI_PATCHES luci-theme-bootstrap.patch"
LUCI_PATCHES="$LUCI_PATCHES luci-olsr-view.patch"
LUCI_PATCHES="$LUCI_PATCHES luci-olsr6.patch"
LUCI_PATCHES="$LUCI_PATCHES luci-freifunk-map.patch"
LUCI_PATCHES="$LUCI_PATCHES luci-freifunk-gwcheck.patch"
LUCI_PATCHES="$LUCI_PATCHES luci-po-only-en-de.patch"
LUCI_PATCHES="$LUCI_PATCHES luci-community-profiles-berlin.patch"
LUCI_PATCHES="$LUCI_PATCHES luci-mod-admin-dfs.patch"
LUCI_PATCHES="$LUCI_PATCHES luci-admin-core-sysauth-https.patch"
LUCI_PATCHES="$LUCI_PATCHES luci-addons-rm-firewall-dep.patch"

MAKE=${MAKE:-make V=s}

[ -z $verm ] && exit 1
[ -z $ver ] && exit 1

for board in $boards ; do
	[ -f "update-build-$verm-$board.lock" ] && echo "build $verm-$board are running. if not do rm update-build-$verm-$board.lock" && exit 1
done


update_git() {
	url="$1"
	repodir="$2"
	revision_c="$3"
	revision_o=""
	if [ -d $repodir ] ; then
		if [ -d $repodir/.svn ] ; then
			echo "please remove the svn repo: $repodir"
			echo "mv $repodir $repodir.bak"
			exit 1
		fi
		cd $repodir
		git add .
		git reset --hard
		git checkout origin/master .
		git remote rm origin
		git remote add origin $url
		git pull -u origin master || exit 1
		revision_o="$(git rev-parse HEAD)"
		echo "update $repodir git pull $revision_c $revision_o"
		[ -z $revision_c ] || case "$revision_c" in
				"$revision_o");;
				*)
					echo "git checkout $revision_c"
					git checkout $revision_c || exit 1
				;;
		esac
		revision=$(git rev-parse HEAD)
		cd ../
	else
		git clone $url $repodir || exit 1
		cd $repodir
		revision_o="$(git rev-parse HEAD)"
		echo "create $repodir git clone $revision_c $revision_o"
		[ -z $revision_c ] || case "$revision_c" in
				"$revision_o");;
				*)
					echo "git checkout $revision_c"
					git checkout $revision_c || exit 1
				;;
		esac
		revision=$(git rev-parse HEAD)
		cd ../
	fi
}

make_feeds() {
	echo "Generate feeds.conf"

	>feeds.conf

	echo "src-link packages $pwd/$packages_dir" >> feeds.conf
	case $verm in
		trunk)
			echo "src-link packagesgithub $pwd/$packages_github_dir" >> feeds.conf
			echo "src-link luci2ui $pwd/luci2_ui" >> feeds.conf
		;;
		barrier_breaker)
			echo "src-link packagesgithub $pwd/$packages_github_dir" >> feeds.conf
			echo "src-link luci2ui $pwd/luci2_ui" >> feeds.conf
		;;
	esac
	echo "src-link routing $pwd/routing" >> feeds.conf
	echo "src-link packagesberlin $pwd/packages_berlin" >> feeds.conf
	echo "src-link luci $pwd/luci-master" >> feeds.conf
	echo "src-link libremap $pwd/libremap-agent-openwrt" >> feeds.conf
	echo "src-link kadnode $pwd/KadNode/openwrt" >> feeds.conf
	echo "src-link fffeeds $pwd/feeds" >> feeds.conf

	echo "openwrt feeds update"
	scripts/feeds update

	echo "openwrt feeds install"
	scripts/feeds install -a
}

apply_patches() {
	patches_dir=""
	if [ -d ../firmware-berlin/patches ] ; then 
		patches_dir="../firmware-berlin/patches";
	elif [ -d ../../firmware-berlin/patches ] ; then
		patches_dir="../../firmware-berlin/patches";
	fi
	for i in $@ ; do
		pparm='-p1'
		patch $pparm < $patches_dir/$i || {
			echo "Patch $i fail"
			exit 1
		}
		mkdir -p ../$verm/patches
		cp $patches_dir/$i ../$verm/patches || exit 1
	done
}

revision=""
case $verm in
	trunk)
		update_git "git://git.openwrt.org/openwrt.git" "openwrt-trunk" "$openwrt_revision"
		echo "openwrt Revision: $revision"  >>VERSION.txt
	;;
	barrier_breaker)
		update_git "git://git.openwrt.org/$ver/openwrt.git" "openwrt-$verm" "$openwrt_revision"
		echo "openwrt Revision: $revision"  >>VERSION.txt
	;;
	*)
		update_git "git://git.openwrt.org/$ver/openwrt.git" "openwrt-$verm" "$openwrt_revision"
		echo "openwrt Revision: $revision"  >>VERSION.txt
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
echo "openwrt Revision: $revision" >>VERSION.txt

[ -d feeds ] || mkdir feeds

[ -d $verm/patches ] || mkdir -p $verm/patches
rm -f $verm/patches/*.patch
update_git "git://github.com/libremap/libremap-agent-openwrt.git" "libremap-agent-openwrt" "$libremap_revision"
echo "libremap-agent-openwrt Revision: $revision"  >>VERSION.txt
update_git "git://github.com/mwarning/KadNode.git" "KadNode" "$kadnode_revision"
echo "KadNode Revision: $revision"  >>VERSION.txt
update_git "git://github.com/freifunk/packages_berlin.git" "packages_berlin" "$packages_berlin_revision"
echo "packages_berlin Revision: $revision"  >>VERSION.txt
update_git "git://github.com/openwrt-routing/packages.git" "routing" "$routing_revision"
echo "routing packages Revision: $revision"  >>VERSION.txt
update_git "git://git.openwrt.org/project/luci2/ui.git" "luci2_ui" "$luci2_ui_revision"
echo "LuCI2 UI modules Revision: $revision"  >>VERSION.txt

cd routing
apply_patches $ROUTING_PATCHES
rm -rf $(find . | grep \.orig$)
cd ..


case $verm in
	trunk)
		update_git  "git://git.openwrt.org/packages.git" "packages" "$packages_revision"
		echo "packages Revision: $revision" >>VERSION.txt
		packages_dir="packages"
		update_git "git://github.com/openwrt/packages.git" "packages_github" "$packages_github_revision"
		echo "openwrt packages GitHub Revision: $revision"  >>VERSION.txt
		packages_github_dir="packages_github"
	;;
	barrier_breaker)
		update_git  "git://git.openwrt.org/packages.git" "packages" "$packages_revision"
		echo "packages Revision: $revision" >>VERSION.txt
		packages_dir="packages"
		update_git "git://github.com/openwrt/packages.git" "packages_github" "$packages_github_revision"
		echo "openwrt packages GitHub Revision: $revision"  >>VERSION.txt
		packages_github_dir="packages_github"
	;;
	*)
		update_git  "git://git.openwrt.org/$ver/packages.git" "packages_$ver" "$packages_revision"
		echo "packages Revision: $revision" >>VERSION.txt
		packages_dir="packages_$ver"
	;;
esac


cd $packages_dir
apply_patches $PACKAGES_PATCHES
rm -rf $(find . | grep \.orig$)

cd ..

update_git "git://git.openwrt.org/project/luci.git" "luci-master" "$luci_revision"
echo "luci Revision: $revision"  >>VERSION.txt
cd luci-master
apply_patches $LUCI_PATCHES
rm -rf $(find . | grep \.orig$)
git rm contrib/package/freifunk-policyrouting/files/etc/rc.d/S15-freifunk-policyrouting
cd ..

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
	rsync -lptgod --delete bin/*/packages/*	$wwwdir/$verm/$ver-timestamp/$timestamp/$board/packages
	cp build_dir/target-$arch*/root-*/usr/lib/opkg/status $wwwdir/$verm/$ver-timestamp/$timestamp/$board$build_profile/opkg-status.txt
	cp VERSION.txt	$wwwdir/$verm/$ver-timestamp/$timestamp/$board$build_profile
	cp .config	$wwwdir/$verm/$ver-timestamp/$timestamp/$board$build_profile/config.txt

	#relativ
	rm -f	$wwwdir/$verm/$ver/$board$build_profile/*
	mkdir -p	$wwwdir/$verm/$ver/$board$build_profile
	rsync -lptgoDd bin/*/*	$wwwdir/$verm/$ver/$board$build_profile
	rm -rf $wwwdir/$verm/$ver-timestamp/$timestamp/$board$build_profile/packages
	mkdir -p $wwwdir/$verm/$ver/$board/packages
	rsync -lptgod --delete bin/*/packages/* $wwwdir/$verm/$ver/$board/packages
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
	pwd=$PWD
	echo "Board: $pwd/$verm/$board"
	mkdir -p $verm/$board
	cd $pwd/$verm/$board
	echo "clean up"
	rm -f .config
	rm -rf files
	mkdir -p files
	case $verm in
		trunk) 
			echo "rsync --delete -a $pwd/openwrt-trunk/* ./"
			rsync --delete -a $pwd/openwrt-trunk/* ./
			rsync --delete -a $pwd/openwrt-trunk/.git ./
			;;
		*)
			echo "rsync  --delete -a $pwd/openwrt-$verm/* ./"
			rsync --delete -a $pwd/openwrt-$verm/* ./
			rsync --delete -a $pwd/openwrt-$verm/.git ./
			;;
	esac

	cp $pwd/VERSION.txt VERSION.txt
	echo "OpenWrt Branch: $verm" >> VERSION.txt
	echo "OpenWrt Board: $board" >> VERSION.txt
	echo "OpenWrt Build: $vername-$build_number" >> VERSION.txt
	#cat $pwd/firmware-berlin/patches/ascii_backfire.txt >> package/base-files/files/etc/banner
	cp VERSION.txt package/base-files/files/etc
	echo "timestamp: $timestamp url: http://$servername/$verm/$ver/$board host: $(hostname)">> package/base-files/files/etc/banner
	options_ver=""
	options_ver=$options_ver" CONFIG_VERSION_NUMBER=\"$vername-$build_number\""

	make_feeds

	PATCHES=""
	case $verm in
		trunk)
			#PATCHES="$PATCHES kvm-hotplug-pci-config.patch"
			#PATCHES="$PATCHES target-atheros-disable-pci-usb.patch" #no trunk
			PATCHES="$PATCHES whr-hp-ag108-sysupgrade.patch" #no trunk
			options_ver=$options_ver" CONFIG_VERSION_REPO=\"http://$servername/$verm/$ver/$board/packages\""
			;;
		barrier_breaker)
			PATCHES="$PATCHES bb-package-mac80211-regdb.patch"
			#PATCHES="$PATCHES bb-package-mac80211-dfs.patch"
			PATCHES="$PATCHES bb-target-atheros-whr-hp-ag108-sysupgrade.patch"
			#PATCHES="$PATCHES bb-target-mpc85xx-profile-wpad.patch"
			#PATCHES="$PATCHES bb-target-ib-ppc-dtc-dts.patch"
			PATCHES="$PATCHES bb-comgt-dep-ppp.patch"
			PATCHES="$PATCHES bb-package-openssl-broken.patch"
			options_ver=$options_ver" CONFIG_VERSION_REPO=\"http://$servername/$verm/$ver/$board/packages\""
			;;
		attitude_adjustment)
			#PATCHES="$PATCHES aa-package-iw-trunk.patch"
			PATCHES="$PATCHES aa-package-iwinfo-trunk.patch"
			PATCHES="$PATCHES aa-package-mac80211-dfs.patch"
			PATCHES="$PATCHES aa-package-mac80211-regdb.patch"
			PATCHES="$PATCHES aa-package-hostapd-dfs.patch"
			PATCHES="$PATCHES target-brcm2708-gzip.patch"
			PATCHES="$PATCHES target-brcm2708-kernel-config.patch"
			PATCHES="$PATCHES target-brcm2708-spi-i2c.patch"
			PATCHES="$PATCHES target-brcm2708-gpu-fw.patch"
			PATCHES="$PATCHES target-brcm2708-inittab.patch"
			PATCHES="$PATCHES kvm-hotplug-pci-config.patch"
			PATCHES="$PATCHES target-x86_kvm_guest-add-qcow.patch"
			PATCHES="$PATCHES target-x86_kvm_guest-add-packages.patch"
			PATCHES="$PATCHES target-x86_alix2-rm-packages.patch"
			PATCHES="$PATCHES target-ixp4xx-avila-sysupgrade.patch"
			PATCHES="$PATCHES target-atheros-disable-pci-usb.patch" #no trunk
			PATCHES="$PATCHES aa-target-atheros-whr-hp-ag108-sysupgrade.patch"
			PATCHES="$PATCHES package-cyassl-2.6.0.patch"
			PATCHES="$PATCHES target-ib.patch"
			PATCHES="$PATCHES package-6relayd.patch"
			PATCHES="$PATCHES target-ar71xx-add-usbserial-comgt-to-profile.patch"
			PATCHES="$PATCHES target-au1000-add-usbserial-comgt-to-profile.patch"
			PATCHES="$PATCHES target-au1000-sysupgrade.patch"
			PATCHES="$PATCHES target-brcm47xx-add-usbserial-comgt-to-profile.patch"
			PATCHES="$PATCHES target-brcm63xx-add-usbserial-comgt-to-profile.patch"
			PATCHES="$PATCHES target-brcm2708-add-usbserial-comgt-to-profile.patch"
			PATCHES="$PATCHES target-ixp4xx-add-usbserial-comgt-to-profile.patch"
			PATCHES="$PATCHES target-x86-add-usbserial-comgt-to-profile.patch"
			PATCHES="$PATCHES target-ar71xx-add-ATH79_MACH_RB_2011US.patch"
			PATCHES="$PATCHES target-ar71xx-add-ath5k-rs.patch"
			PATCHES="$PATCHES aa-comgt-dep-ppp.patch"
			options_ver=$options_ver" CONFIG_VERSION_REPO=\"http://$servername/$verm/$ver/$board/packages\""
			;;
	esac
	PATCHES="$PATCHES base-system.patch"
	apply_patches $PATCHES
	rm -rf $(find package | grep \.orig$)
	rm -rf $(find target | grep \.orig$)
	
	mkdir -p $pwd/dl
	[ -h dl ] || ln -s $pwd/dl dl
	cp -a $pwd/firmware-berlin/patches/regulatory.bin dl/regulatory.bin
	build_fail=0

	case $board in
		atheros)
			echo "copy config $pwd/firmware-berlin/configs/$verm-$board.config .config"
			cp $pwd/firmware-berlin/configs/$verm-$board.config .config
			rm staging_dir/host/bin/*-pc-linux-gnu-pkg-config
			genconfig "$options_ver"
			make oldconfig
			#Disable Audio,PCI and USB#################################
			genconfig "CONFIG_AUDIO_SUPPORT=n"
			genconfig "CONFIG_PCI_SUPPORT=n"
			genconfig "CONFIG_USB_SUPPORT=n"
			${MAKE} world || build_fail=1
		;;
		ar71xx_nand)
			#make initramfs
			echo "copy config $pwd/firmware-berlin/configs/$verm-$board-initramfs.config .config"
			cp $pwd/firmware-berlin/configs/$verm-$board-initramfs.config .config
			rm staging_dir/host/bin/*-pc-linux-gnu-pkg-config
			echo "$options_ver"
			genconfig "$options_ver"
			make oldconfig
			${MAKE} world || build_fail=1
			#make nand rootfs
			echo "copy config $pwd/firmware-berlin/configs/$verm-$board.config .config"
			cp $pwd/firmware-berlin/configs/$verm-$board.config .config
			rm staging_dir/host/bin/*-pc-linux-gnu-pkg-config
			echo "$options_ver"
			genconfig "$options_ver"
			make oldconfig
			${MAKE} world || build_fail=1
		;;
		*)
			echo "copy config $pwd/firmware-berlin/configs/$verm-$board.config .config"
			cp $pwd/firmware-berlin/configs/$verm-$board.config .config
			rm staging_dir/host/bin/*-pc-linux-gnu-pkg-config
			echo "$options_ver"
			genconfig "$options_ver"
			make oldconfig
			${MAKE} world || build_fail=1
		;;
	esac
	if [ $build_fail -eq 1 ] ; then
		rm $pwd/update-build-$verm-$board.lock
		exit 1
	fi
	cd $pwd
	rm update-build-$verm-$board.lock
	) >update-build-$verm-$board.log 2>&1
done

