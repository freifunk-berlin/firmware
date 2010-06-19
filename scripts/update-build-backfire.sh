#!/bin/sh

. ./config

for board in $boards ; do
	echo "to see the log just type:"
	echo "tail -f update-build-$verm-$board.log"
	>update-build-$verm-$board.log
#	(
	echo "Board: $board"
	mkdir -p $verm/$board
	cd $verm/$board
	echo "clean up"
	rm -f .config
	rm -rf ./tmp
#	rm -rf ./feeds/*
	rm -rf ./feeds/*.tmp
	rm -rf ./feeds/*.index
	rm -rf ./package/feeds/*
	rm -rf ./bin
#	rm -rf build_dir/*/*luci*
#	rm -rf build_dir/*/lua*
#	rm -rf dl/*luci*
	rm -rf $(find . | grep \.rej$)
	rm -rf $(find . | grep \.orig$)
#	rm -rf ./build_dir
#	rm -rf ./staging_dir

	openwrt_revision=$(wget -q -O - $server/$board/VERSION.txt | grep OpenWrt | sed -e 's/.*(r\(.*\)).*/\1/')
	echo "switch to openwrt revision: $openwrt_revision"
	rm -rf $(svn status)
#	svn sw -r $openwrt_revision svn://svn.openwrt.org/openwrt/branches/8.09
#	svn co svn://svn.openwrt.org/openwrt/$verm ./
	svn co svn://svn.openwrt.org/openwrt/branches/$verm ./
	svn up
	#rm -rf package/mac80211
	openwrt_revision=$(svn info | grep Revision | cut -d ' ' -f 2)
	echo "Generate feeds.conf"
	>feeds.conf
	cat <<EOF >> feeds.conf
src-svn packages svn://svn.openwrt.org/openwrt/packages
src-svn ffx http://svn.ffx.subsignal.org/packages
src-link ffcontrol ../../../ff-control
EOF
	#src-svn luci http://svn.luci.subsignal.org/luci/branches/luci-0.9/contrib/package
	#src-svn luci http://svn.luci.subsignal.org/luci/trunk/contrib/package
	
	if [ -d ../../piratenfreifunk-packages ] ; then
		echo "update piratenluci manual git pull"
		#cd ../../piratenluci.git;git pull; cd ../8.09/$board
	else
		echo "create piratenluci git clone"
		cd ../../
		git clone git://github.com/basicinside/piratenfreifunk-packages.git
		cd $verm/$board
	fi
	echo "src-link piratenluci ../../../piratenfreifunk-packages" >> feeds.conf

# 	if [ -d ../../luci-trunk ] ; then
# 		echo "update luci-trunk manual svn up"
# 		#cd ../../piratenluci.git;git pull; cd ../8.09/$board
# 	else
# 		echo "create luci-trunk svn co"
# 		cd ../../
# 		svn co http://svn.luci.subsignal.org/luci/trunk luci-trunk
# 		cd $verm/$board
# 	fi
# 	echo "src-link luci ../../../luci-trunk" >> feeds.conf
	
	if [ -d ../../luci-0.9 ] ; then
		echo "update luci-0.9 manual svn up"
		#cd ../../piratenluci.git;git pull; cd ../8.09/$board
	else
		echo "create luci-0.9 svn co"
		cd ../../
		svn co http://svn.luci.subsignal.org/luci/branches/luci-0.9 luci-0.9
		cd $verm/$board
	fi
	echo "src-link luci ../../../luci-0.9" >> feeds.conf
	
	
	echo "openwrt feeds update"
	scripts/feeds update
	echo "openwrt feeds install"
	scripts/feeds install -a
	scripts/feeds uninstall libxslt
	scripts/feeds install -p ffcontrol libxslt
	scripts/feeds uninstall xsltproc
	scripts/feeds install -p ffcontrol xsltproc
	#scripts/feeds uninstall uhttpd
	rm -rf package/uhttpd
	scripts/feeds install -p ffcontrol uhttpd
	scripts/feeds uninstall motion
	scripts/feeds install -p ffcontrol motion
	scripts/feeds uninstall olsrd-luci
	scripts/feeds install -p ffcontrol olsrd-luci
#	wget -O build.config $server/$board/build.config
#	mv build.config .config
	sed -i -e "s/downloads\.openwrt\.org/$servername/" package/opkg/files/opkg.conf
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
#	echo "Generate /etc/config/system"
#	mkdir -p files/etc/config
#	> files/etc/config/system
#	cat <<EOF >> files/etc/config/system 
#config 'system'
#	option 'hostname' 'OpenWrt'
#	option 'zonename' 'Europe/Berlin'
#	option 'timezone' 'CET-1CEST,M3.5.0,M10.5.0/3'
#EOF

######################FEAUTURE#################################################################
#	echo "CONFIG_SMP=y" >> target/linux/$board/generic/config-default
#	echo "CONFIG_X86_BIGSMP=y" >> target/linux/$board/generic/config-default
#	echo "CONFIG_X86_HT=y" >> target/linux/$board/generic/config-default
#	echo "CONFIG_NR_CPUS=32" >> target/linux/$board/generic/config-default
#	echo "CONFIG_SCHED_SMT=y" >> target/linux/$board/generic/config-default
#	echo "CONFIG_SCHED_MC=y" >> target/linux/$board/generic/config-default
###############################################################################################
	for i in $PATCHES ; do
		pparm='-p0'
		echo "Patch: $i"
		patch $pparm < ../../ff-control/patches/$i
	done
	cp  ../../ff-control/configs/kifuse02-$verm-$board.config .config
	echo "add ImageBuilder (IB) to config"
	sed -i -e 's/.*\(CONFIG_IB\).*/\1=y/' .config
	mkdir -p ../../dl
	ln -s ../../dl dl
	echo "make V=99 world"
	make V=99 world
	echo "copy ImageBuilder"
	cp bin/$board/OpenWrt-ImageBuilder-$board-for-*.tar.bz2 ../
	mkdir -p $wwwdir/$verm/$ver/$board
	rsync -av --delete bin/$board/ $wwwdir/$verm/$ver/$board
	cd ../../
#	) >update-build-$verm-$board.log 2>&1
done
