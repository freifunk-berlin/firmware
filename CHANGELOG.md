# Changelog

## Version 1.0.1

### overall system
* add migration from previous releases
* add a UCI-option "ffberlin-uplink" which holds the current previous uplink-preset

## Version 1.0.0

### overall system
```
rename interface "ffvpn" to "ffuplink"
move interface "ffvpn" into its own firewall-zone
network-defaults: set interface "wan" as bridge
hostapd: disable 802.11 legacy-rates by default
kernel: bump 4.4 to 4.4.116
openvpn: update to 2.4.4
Update OONF to 0.14.1-1
batman-adv: update to 2016.5
olsrd: stay at v 0.9.0.3 for compatibility with BBB-VPN (https://github.com/OLSR/olsrd/issues/20)
configs: in preinit and failsafe change network to 192.168.42.1/24
for 4MB-models there ist only enough space in the default-image
use OpenVPN-openssl as of RSA1024-keys for VPN03 and BBB-VPN
```

### packages
```
caa7958715 packages: remove "migration" for Hedy-1.0.0
64cd8de4b1 patches: do not run policy-routing script on interface ffuplink
5550d6bb52 configs: add package ffuplink-notunnel (as image-flavor "default")
0b7aa08806 Add "diffutils" and "patch" to optional packages
3dd9eaf575 Allow ICMP for busybox traceroute
8f5085c6f6 configs: build kmod-nf-nathelper-extra as module
cdfd3b0b5e add packages to support setup of ipip-tunnels (also for LuCI)
35e8419d27 packages: add tcpdump to the default package set
ac6dd7c412 configs: add iperf3 and collectd-modules conntrack, irq
d02b09ff62 configs: add PPPoE-support
9a331fb011 configs: remove deprecated 6to4-package
86e155c2df configs: select collectd-dhcp-addon by default
d2f4aa74bb configs: disable "HORST", which fails to build
6d0c0dd52c configs: add package luci-app-wifischedule
```

### hardware-support
```
696871104f Add Raspberry Pi 3 configuration
7251b6648f added RaspberryPi configuration
a0d1ca0ecd backport Ubiquiti ERX SFP to LEDE 17.01
f8dc9aa640 profiles: add TP-Link WR1043ND-v4
```

### feeds
```
5e8f501c2 wizard, uplink-files: add uci-setting to request different auth-types
19cb3cddd dhcp-defaults: don't announce as default-gw
41ea9464b guard: add function "rename_guard <src> <dest>"
f845b3bb3 ffwizard: drop private AP-feature
1288c3dc9 ffwizard, migration: don't create cronjob to restart "wan"
a08be1521 freifunk-defaults: change our settings, which differ from upstream
fa8619e2a freifunk-berlin-freifunk-defaults: use uci-default script
8b7e40011 openvpn-files: depend on virtual-package openvpn-crypto
fa3a118d collectd: fix for uptime plugin
938db714 collectd: upstream fix for vulnerabity in network plugin CVE-2017-7401
3f6a27fbf luci-mod-admin-full: Add mesh_fwding support
33f6527cc luci-mod-admin-full: Add meshId support
426c1043b luci-mod-admin-full: auto-migrate ifnames when changing VLAN configuration
6e412cc78 luci-mod-admin-full: reload wifi settings page after changing countey code
1cd096d29 luci-mod-admin-full: allow unset txpower value
```

### build
```
20e25c82d6 Makefile: do not include git-revision in filename of releases
708240926d Makefile: prefix images with "hedy"
ec06e30ea4 Makefile: add setting "SET_BUILDBOT"
cad82aea78 Makefile: add BUILD env "IS_BUILDBOT"
972e689370 assemble_firmware: skip usecases with empty package-list
97eef0a600 Makefile: new target "images" to only create the firmware-images
86330521ff Makefile: IB_BUILD_DIR is obsoleted by assemble_firmware.sh
cdc1404263 Makefile: remove unused TOOLCHAIN_PATH
e7b8a364d5 Makefile: define separate target for VERSION.txt
105d293ef9 assemble_firmware: check for files in embedded-directory
a66896d3ca Makefile: use openwrt/files to embedd files directly into image
```

packages:
```
2e44ee693 network-defaults: setup the ip rules at runtime
2df127c7a network-defaults: prohibit traffic to net on ffuplink
08474427d uplink-notunnel: setup default-route via hotplug.d
98f0a3442 ffwizard: adapt to new hostname from "system-defaults" package
a29d9a4d3 system-defaults: change the default hostname
e284bc9bd add new package: freifunk-berlin-uplink-tunnelberlin-files
02fb2519b firewall-defaults, wizard: add separate zone ffvpn

```
OpenWRT
```
b934aa2f21 kernel: update 17.01 kernel to 4.4.116
77e79b2dd0 openvpn: update to 2.4.4
108a42bcba ramips: support jumbo frame on mt7621 up to 2k
f0a493160c mac80211: gracefully handle preexisting VIF
f173464f13 base-files: add generic board_name function to functions.sh
b41a2e646e opkg: bump to version 2017-12-08
f5f5f583f9 hostapd: backport fix for wnm_sleep_mode=0
3590316121 dnsmasq: backport infinite dns retries fix
e626942c33 dnsmasq: load instance-specific conf-file if exists
```
also check the releasenotes of underlying LEDE releases
* https://lede-project.org/releases/17.01/notes-17.01.4
* https://lede-project.org/releases/17.01/notes-17.01.3
* https://lede-project.org/releases/17.01/notes-17.01.2
* https://lede-project.org/releases/17.01/notes-17.01.1
* https://lede-project.org/releases/17.01/notes-17.01.0


## Version 0.3.0

* OpenWrt ChaosCalmer of Mar 09, 2017 (9a1fd3e)
  * kernel 3.18.45
* OpenWrt packages of Apr 8, 2017 (b5f4718)
* OpenWrt LuCI of Jan 13, 2017 (b89b022)
* Berlin-packages of Apr 9, 2017 (6bd5486)

### packages
```
dhcp-defaults: quieten dnsmasq
collectd-addons/dnsmasq: package added
```

### hardware-support
```
build GL.inet AR300, MT300a, MT300n
build Buffalo WZRHPG300NH2, WZRHPAG300H, WZR600DHP, WZRHPG450H
build TPlink-WR941
```

### build
Makefile is compatible to the current LEDE-compatible 
```
convert target-names to include always MAINTARGET and SUBTARGET
Makefile: split off firmware assemble from Makefile
append subtarget name to all platforms
```

## Version 0.2.0

* OpenWrt ChaosCalmer of Nov 8, 2016 (1b6dc2e)
  * kernel 3.18.44
  * improved Security, hardware-support
  * fixes bricking NanoStations XM with original-firmware >5.5
* OpenWrt packages of Oct 29, 2016 (e3e9f34)
  * Collectd V5.4.2
* OpenWrt LuCI of Nov 8, 2016 (9047456)
* OpenWrt routing of Jun 7, 2016 (d580d71)
  * olsr v0.9.0.3
  * batman-adv: 2016.1 bugfixes & stability updates
  * OONF release 0.12.1

### packages
```
patches: fix issue#402 (bypass VPN on mesh)
snmp-templates: add template to query Ubiquiti AirMax via SNMP
configs: add package snmp-utils
configs: do not build ffwizard-pberg
[packages] use luci-mod-freifunk-ui
enable CONFIG_PACKAGE_kmod-ppp for PPPoE/PPP/mobile connections
[luci-app-ffwizard-berlin] do not use ffwatchd
packages/default_4MB: remove opkg and usign
build kernel modules for usb-ethernet tethering
[packages]: build luci-app-olsr-viz as package
[configs] build kernel modules for cifs/ext4/vfat, nls, USB ACM/serial/storage
[configs] build luci-app-splash
[configs] build olsrd2
remove l2gvpn package
remove libwebsocket and websocket server implementation
remove auto-ipv6-node package
remove auto-ipv6-gw package
remove ffwizard-pberg
remove luci-app-chat
```

### hardware-support
```
add OpenWRT-support for TP-link WR-842v3
OpenWRT added support for TPlink WR841-v11 and others
add TP-link MR3220 for ar71xx
add GL.inet AR150, AR300, DominioPi, MT300A+N, MT750
add GL-AR150 support
add support for D-Link DIR505 router
Add profile for TP-Link TL-WA801N/ND routers.
add version 1.1 support to CPE210/220/510/520
Add support for Archer C7 v2
add ramips config (Nexx WT3020)
add GL.iNet 6416A
```

### feeds
```
[patches] update OWM API URL
[olsrd-defaults] fix filename of olsr6 watchdog file
network-defaults: add workaround for too high txpower on NanoStation M2
[ffwizard] fix replacing VPN key/cert
fork freifunk-ui from luci-mod-freifunk-ui
[ffwizard] set start and limit in dhcp configuration
[freifunk-berlin-openvpn-files] start OpenVPN via hotplug script, use --local for binding to WAN IP only
Replace dyngw ping check target with stable ones
[ffwizard] remove all references to uci "system.system.latlon"
[ff-berlin-statistics-defaults]: change ping host for collectd
[ffwizard] [migration] use ffvpn for QoS rather than wan
[uhttpd-defaults]: do not force a redirect to https
[owm] add --dry-run option for debugging
```

### config
```
[configs] disable kernel Swap-support
[configs] use LUCI_SRCDIET=y to create smaller rootfs
[configs] disable SSP_SUPPORT
[configs] strip kernel exports
```

### build
```
patches: add PATCHES.rst to introduce a counting structure
Makefile: add target openwrt-clean-bin
Makefile: add unpatch target
[patches] run postinst-script just before building the image
split up configs into common part and arch-specific part
Makefile: create VERSION file with git branch and revision
Set VERSION and REVISION string from this firmware repository
```

## Version 0.1.2

```
[patches] update OLSRd to v0.9.0.2
[feeds] update firmware-packages (OpenVPN mssfix)
```

## Version 0.1.1

* https://github.com/freifunk-berlin/firmware/commits/v0.1.1
* https://github.com/freifunk-berlin/firmware-packages/commits/v0.1.1

## Version 0.1.0

### packages

```
[packages] add basic packages list for backbone nodes (83c5fb3)
[packages] add luci-app-firewall (d6d26f6)
[packages] bbb - add tcpdump (89e14bd)
[packages] build and integrate freifunk-berlin-migration package into firmware (55b9fe5)
[packages] rename lists to 'default' and 'minimal' (8bf3979)
```

### config

```
config.mk: Update OpenWrt revision to 44162 (4fb186f)
[configs] build ath{5,9,10}k wifi drivers as modules for x86 target (5dab54c)
[configs] build tcpdump as optional package (5d6b47a)
[configs] increase VERSION_NUMBER to 0.1.0 (baeed92)
[configs] update default packages list (848bc23)

```

### feeds

```
[feeds] change url for packages berlin to new repo url (dbf79a8)
[feeds] update feeds to include vpn03-firewall fix (a72f5de)
[feeds] update packages berlin (0e62c8f)
[feeds] update packages_berlin (8b524d0)
[feeds] update packages_berlin feed (363e526)
[feeds] update packages_berlin feed (fc2e535)
[feeds] update routing feed (5a46b41)
[feeds] update routing feed (a1018bb)
[feeds] update routing feed (b98f5f2)
```

### patches

```
[patches] add two ipv6 nameservers (83df6ab)
[patches] backport support for ubnt loco xw (7142d00)
[patches] change default dhcp leasetime to 5 minutes (b38af12)
[patches] fix ascii art in /etc/banner (99a4382)
[patches] fix ascii art in /etc/banner (9c8394c)
[patches] fix firstboot checkpasswd condition (6c943d9)
[patches] fix redirect on firstboot (8dc3728)
[patches] fix regression introduced by openvpn update in openwrt release (08762ad)
[patches] remove 008-luci-freifunk-gwcheck.patch (5328184)
[patches] remove dead code and add a comment (afaef84)
[patches] remove olsrd PingCmd patch (now in upstream release) (1cfb3e6)
[patches] remove the PingCmd patch from series file (3f66f8c)
[patches] remove unused regdb.txt patch (ec39bf0)
```

### build

```
[profiles] add support for TL-WR710N (6ac7e57)
[Makefile] fix wrong directory for packages (613875b)
[Makefile] new firmware directory layout (e40935f)
[Makefile] only copy imagebuilder once for each target (1260cda)
[Makefile/Packages] rename minimal to backbone (c2413e2)
[Makefile] Support for different packages lists (066e80e)
remove 4MB constraint from mikrotik profile (74e8316)
update openwrt/packages to head of branch for-14.07 (9b2c15c)
```

### misc

```
CHANGELOG.md: fix version number (a309bbf)
CHANGELOG.md: Fix markdown for CHANGELOG.md (9b0693b)
fix multiple policyrouting rules (9a72280)
fix policyrouting typo (208aada)
[README] add firmware directory layout (9ca1762)
[README] add ipv6 resolvers to feature list (811566d)
[README] fix imagebuilder location (847302e)
[README] mention some prerequisites for the build process and add some links (cba0a89)
[README] some restructuring; buildbot/branch notes; news part I (06abf0f)
```

## Version 0.0.0

### Packages

```
[packages] added luci-app-openvpn (092822a)
[packages] Add batctl to list (86de22f)
[packages] add collectd-mod-uptime and -mod-memory (32962c8)
[packages] added alfred to package list (337c54c)
[packages] added mtr to minimal list (35ade53)
[packages] add freifunk-berlin-firewall-defaults (e474626)
[packages] add freifunk-berlin-statistics-defaults (3731064)
[packages] add olsrd-mod-txtinfo (7e627e4)
[packages] add olsrd-mod-txtinfo and olsrd-mod-dyn-gw (f59e432)
[packages] move default values for olsr and network in own packages (bfe776d)
[packages] add px5g (4e8680a)
[packages] refactoring and removing unnecessary entries (ec94dc8)
[packages] refactor packages (80413ae)
[packages] remove 6to4 (61bcec0)
[packages] remove duplicate olsrd-mod-jsoninfo package (8ac0530)
[packages] remove wpad package (a845e14)
[packages] remove wpad (pulled in by mpc85xx) (0e6b5b6)
[packages] remove alfred from ar71xx.config (488f240)
[packages] remove auto-ipv6-{gw,node} from ar71xx.config (7a0d190)
[packages] remove olsrd-plugin-txtinfo (fix #103) (b01b4ca)
[packages] rename package list 'minimal' to 'vpn' (f42dc9c)
[packages] replace ar71xx.config with sane new config (130b8e1)
[packages] Add default packages for dhcp and freifunk (646e295)
[packages] Added additional packages to configs (227c13d)
[packages] Added freifunk-berlin-openvpn-files and freifunk-policyrouting (77fcddc)
[packages] Added package tmux to configs (0efc3ca)
[packages] Adding python to the list of missing pakages. (Missing for docker ubuntu images) (15cd128)
```

### Config

```
[configs] Added rudimentary packages list (024cafb)
[configs] #7 added luci-app-firewall package (c4db051)
[configs] do not use IGNOE_ERRORS=m (ced9337)
[configs] update openwrt revision (latest change) (e6abd81)
[configs] update openwrt revision to latest revision (4a6fcbb)
[configs] add community-profiles to ar71xx.config (2090804)
[configs] added alfred as package fixed dyn_gw (9f6e774)
[configs] added mtr as package to build (684647a)
[configs] add freifunk-berlin-firewall-default package (e949442)
[configs] add lib-guard, statistics-default and olsrd-mod-txtinfo (ee367b8)
[configs] add om-watchdog for OM2P target (1ec3938)
[configs] add px5g (00d8cc5)
[configs] add px5g to ar71xx.config (402ec38)
[configs] add x86 as target (42ca4df)
[configs] build with SSP_SUPPORT/libssp (d88f13c)
[configs] enable DFS support in ar71xx.config (1541177)
[configs] fix #20 VERSIONOPT bug (484d68a)
[configs] honor users regdb configuration (3b609e4)
[configs] only build image builder for ar71xx (83dc48b)
[configs] remove ppp support and some kernel debug flags (268812b)
[configs] set version information (622576d)
[configs] strip polarssl (aa81db0)
[configs] update repo link to buildbot (8e685fd)
[configs] update routing and luci (8b9a534)
[configs] update ar71xx (3229ebe)
[configs] fix https duplicated commonname/issuer id problem (e703655)
[configs] use barrier breaker 14.07 branch (92a31ed)
[configs] Add minimal package lists for 4MB flash devices (09bf78c)
[configs] add OM2P boards to ar71xx profiles (fbacfc5)
[configs] Add support for different default packages list (92f8ba9)
[configs] Add target 'x86' (aea021f)
[configs] update ar71xx.config to current openwrt revision (92a310e)
[configs] update luci feed and remove obsolete map patch (d0d4284)
[configs] Update OpenWRT version (e5737d7)
```

### Feeds

```
[feeds] packages_berlin ffwizard added qos script (fb78ccd)
[feeds] packages_berlin ffwizard set mac addr if present (4e3f5e9)
[feeds] packages_berlin firewalldefaults Add unreachable rules for tunl0 (f7fb9a0)
[feeds] update routing feeds (9877987)
[feeds] packages_berlin olsrddefauls ipv6 stuff (15e7724)
[feeds] update olsrd to 0.6.7.1 (66dfd72)
[feeds] update luci feed (3b4e592)
[feeds] adapt feeds for freifunk (e4ef5a6)
[feeds] add support for statistics (e1d5f4b)
[feeds] bugfixes for ffwizard and freifunk-defaults  freifunk-defaults - add missing firewall rules  ffwizard-berlin - set wan type to bridge for private APs (63d7cdf)
[feeds] change page order of optional stuff and wireless (a31ed55)
[feeds] configure olsrd with defaults values from community_profile (ce2ffed)
[feeds] update luci feed and rebase/remove patches (087fc30)
[feeds] update revision of packages-berlin remove defaults from wizard (e714ddd1)
[feeds] ffwizard - activate dhcpv6+ra server mode for odhcpd for dhcp network (787b311)
[feeds] ffwizard-berlin: firewall - add dhcp to freifunk zone (95f4a51)
[feeds] ffwizard-berlin - only configure statistics if installed (8963389)
[feeds] ffwizard-berlin support wifi iface5, osm tiles (9f6c437)
[feeds] ffwizard-berlin - use HT40 only for channels 36..100 (2e353a9)
[feeds] fix copy/paste error in uci-defaults of ffwizard-berlin (9bf4324)
[feeds] fix zoom level for map in ffwizard-berlin (0696a93)
[feeds] olsrd defaults - add RtTablePriority to fix netlink errors (9f057b3)
[feeds] pin down all feeds to a specific commit (886ccf9)
[feeds] update berlin-packages always enable policy routing (65e57cb)
[feeds] update berlin-packages ix openwifimap, wireless ap config (57a8c1b)
[feeds] update berlin-packages update for smartgw and dyngw (470aea0)
[feeds] updated packages_berlin add lib guard fix ipinfo (af6aa36)
[feeds] update ffwizard-berlin fix countryCode,olsr, qos (821a29f)
[feeds] update ffwizard-berlin wizard with map, private ap, vap (7e2652b)
[feeds] update luci feed (3b4e592)
[feeds] update package_berlin (9919dd4)
[feeds] update package_berlin change default ip to 192.168.42.1, add static
[feeds] update package_berlin remove p2pblock, added switch-ports to br-dhcp (ff83bd4)
[feeds] update packages-berlin no ipip tunnel if uplink (e336804)
[feeds] update packages_berlin update openvpn setup (b79c5d4)
[feeds] update packages_berlin toggle stats in wizard (c9d419f)
[feeds] use dyngw instead of dyngw_plain+ff_olsr_gwcheck (ec593c6)
[feeds] use ffwizard-berlin (1580033)
```

### Patches

```
[patches] update olsrd dynamic gw ping cmd patch (8f90f36)
[patches] remove olsrd ipv6 bind only patch (366ea66)
[patches] add fix for mac address issues for wdr4900 (4fd9c3f)
[patches] firstboot - fix auth parameters (734e95e)
[patches] pr - add rule for tunl0 to olsr-tunnel (b0901b9)
[patches] #18 redirect to ffwizard without login (5732ad5)
[patches] #18 redirect to freifunk wizard on first boot (3085cc6)
[patches] #41 change ssid to berlin.freifunk.net (5d4f9e1)
[patches] add barrier breaker patches (38aa6b7)
[patches] add bind ipv6 only patch for olsrd txtinfo and jsoninfo (6cb7a33)
[patches] add default values for olsrd to community_profile (90e8e97)
[patches] added freifunk gwcheck jshn patch (ac0327a)
[patches] Add Freifunk to /etc/banner (fcc948b)
[patches] add patch for hostapd dfs (2e1297e)
[patches] add '%' to valid olsrd option values (7e14e99)
[patches] adjust to new ffwizard config (d55358e)
[patches] firstboot - only set username/password in url if password is blank (24ada56)
[patches] fix #79 - invalid autogenerated olsrd config (fd4638c)
[patches] fix name of freifunk-policyrouting-hotplug-device patch (323941b)
[patches] fix paths of jshn-patch (8a8ec63)
[patches] import luci-freifunk-gwcheck.patch (005aabe)
[patches] import luci-freifunk-map.patch (75ced53)
[patches] import luci-freifunk-policyrouting-berlin.patch (0c748b6)
[patches] import luci-mod-admin-dfs.patch (08f5ed0)
[patches] import luci-olsr-controller.patch (c508d1a)
[patches] incorporate fixes for olsrd dynamic gateway ping command patch (5592edb)
[patches] merge profile berlin patches (563c955)
[patches] olsrd - add dyn gw PingCmd param (66cc0a8)
[patches] profile_berlin - add country and mcast_rate (e90753e)
[patches] profile_berlin - add wifi_device and _iface for 5GHz (5823e89)
[patches] redirect only if no password is set (fec200b)
[patches] remove 002-target-atheros-whr-hp-ag108-sysupgrade.patch (28f5d22)
[patches] remove 003-comgt-dep-ppp.patch (a1d895c)
[patches] remove 004-package-openssl-broken.patch (802e72b)
[patches] remove 006-target-imagebuilder-remove-initramfs-dep.patch (d7cf86f)
[patches] removed dfs related patch which breaks /sbin/wifi (d5b1e73)
[patches] remove !initramfs dependency of imagebuilder (ae80af8)
[patches] remove non existent freifunk community profiles (6c49443)
[patches] remove obsolete olsr defaults (4558f8c)
[patches] remove owm_api and mapserver key from community profile (d4ee2e1)
[patches] remove redundant country param in profile_berlin (0185677)
[patches] remove RtTableTunnel for olsrd6 (a0cb0ea)
[patches] rename 007-routing-olsrd-ipv6-bind-only.patch (9abde9d)
[patches] rename dev to DEVICE in freifunk-policyrouting hotplug script (96007ff)
[patches] set netmask for interfaces to 255.255.255.255 (c0d736b)
[patches] use intern-chXX.freifunk.net as ssid scheme for adhoc (6ce8f59)
[patches] use luci.model.ipkg instead of luci.fs to check if wizard is installed (4a0e6a7)
```

### Build

```
[Makefile] add images target (1ea1da7)
[makefile] add MAKE_ARGS (8aaf7ce)
[Makefile] add pre-patch target (3f4fe00)
[makefile] compile and build firmwares by default (60a0218)
[makefile] use diffconfigs (1f90d9b)
[makefile] do not execute imagebuilder manually (bc51253)
[makefile] fix parallel issues (653ade2)
[makefile] fix patches symlink (70f014f)
[Makefile] fix possible issue with imagebuilder (979539a)
[Makefile] fix quilt dir (48af529)
[Makefile] quilt from openwrt toolchain for patching (9d259a7)
[makefile] images target -> firmware target (7df4262)
[Makefile] inject config after patches have been applied (3aa788b)
[Makefile] let make clean invoke ./scripts/feeds clean (fa2f1ad)
[makefile] moarrr profile fixes (361de16)
[Makefile] place binaries in expanded target dir (with subtarget) (7f1eb98)
[makefile] revamp makefile with stamp files (0b314b6)
[Makefile] set SHELL to bash (471c0f1)
[Makefile] set umask to 022 (c8d46aa)
[makefile] support multiple profiles (7e28bd1)
[makefile] support subtargets (178ff19)
[makefile] add configurable make command MAKE_CMD (a8a8ad1)
[makefile] also remove repositories with git clean (4f2cd3e)
[makefile] apply patches w/ quilt (d80f181)
[makefile] fix PWD (13a176b)
[makefile] remove build.sh (8c9cf59)
[makefile] remove generate.sh (f0b3169)
[makefile] terminate if git checkout fails (ee637cb)
[makefile] uninstall feeds (126190a)
[makefile] use absolute paths (bfc499d)
[makefile] use git branches. Disable AA, enable BB by default (671ee3e)
```

