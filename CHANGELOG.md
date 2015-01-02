# Changelog

## Version 0.1.0

```
Fix markdown for CHANGELOG.md
README: add ipv6 resolvers to feature list
Update OpenWRT revision to r43077
[configs] build tcpdump as optional package
[feeds] change url for packages berlin to new repo url
[feeds] update packages_berlin feed
[makefile]remove 4MB constraint from mikrotik profile
[packages]: build and integrate freifunk-berlin-migration package into firmware
[packages]: build ath{5,9,10}k wifi drivers as modules for x86 target
[patches] add two ipv6 nameservers
[patches] backport support for ubnt loco xw
[patches] fix firstboot checkpasswd condition
[patches] remove unused regdb.txt patch
[patches]: change default dhcp leasetime to 5 minutes
[patches]: fix ascii art in /etc/banner
fix multiple policy-routing rules in the hotplug.d scripts
fix version number in CHANGELOG.md
update openwrt/packages
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

