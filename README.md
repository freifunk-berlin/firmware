# Freifunk Firmware Berlin "Hedy"
https://wiki.freifunk.net/Berlin:Firmware

*[Hedy Lamarr](https://en.wikipedia.org/wiki/Hedy_Lamarr#Inventor) and composer George Antheil developed in 1942 a torpedo guidance system using spread spectrum and frequency hopping technology which is still the base for Wi-Fi and other radio technologies*.

This release removes the hardlinked VPN03-tunnel. Now it is possible to use different flavours of tunnels as well as no tunnel to connect to the internet. Additionally Mesh (11s) is now supported in LuCi to mesh native instead of IBSS. Also it is intended to catch up with current software development and to offer a stable firmware for Freifunk mesh in Berlin.

The firmware is based on vanilla [OpenWrt](https://openwrt.org/start) with some modifications (to fix
broken stuff in OpenWrt itself or for example LuCI) and additional default packages/configuration settings.
New features like a new network concept will be part of future releases.

## Release Note 1.0.1 "Hedy" - 2018-05-29
* just a small maintenance release for Hedy-1.0.0, which brings the missing upgrade possibility from previous releases
* images for 
  * Ubiquiti ERX SFP, TP-Link WR1043ND-v4
  * support for RaspberryPi and RaspberryPi3 (compile yourself)
* introduces interface "ffuplink" for a flexible configuration of the wired uplink
* improved support of 802.11s mesh in LuCI
* disabling of 802.11b wifi-rates by default
* in preinit and failsafe it IP-address is 192.168.42.1/24 (like an unconfigured node)
* the LAN-interface (br-lan) is not providing a default route on a unconfigured node, so manual reconfiguration is required when not using the assistent
* the assistent will not offer the setup of a private AP anymore
* when changing or initially confiuring VLANs (via LuCI) the interfacenames will also be changed (should fix #388)
* a lot of security-fixes for linux and many packages (since Kathleen 0.3.0)

## Features
* based on [OpenWrt](https://openwrt.org/start) v17.01.4+ (lede-17.01 branch)
  * Linux 4.4.116
  * OLSR 0.9.0.3 (downgraded for BBB-VPN compatibility)
  * B.A.T.M.A.N. 2016.5
* custom package lists for different settings
  * "default" variant includes ffwizard, openvpn, BATMAN
  * "default_4MB" like the "default" variant, but excludes public router statistics page (luci-mod-freifunk), monitoring (collectd), BATMAN to fit into boards with 4MB flash
  * "tunnel-berlin" like default variant and uses the tunnel-service of the Berlin-community as default uplink
  * "vpn03" like default variant and uses the VPN03-service (deprecated) as default uplink
  * "backbone" variant excludes ffwizard and openvpn, includes more debugging tools
  * "backbone_4MB" variant excludes ffwizard, luci-mod-freifunk, openvpn, collectd, includes BATMAN and more debugging tools
* new OLSR setup and configuration:
  * SmartGateway for gateway selection (e.g. honors uplink speed)
  * dynamic gateway plugin for uplink connectivity tests (gwcheck script removed)
    on hosts: 85.214.20.141, 213.73.91.35, 194.150.168.168
* a configuration [wizard](https://github.com/freifunk-berlin/packages-berlin/tree/master/utils/luci-app-ffwizard-berlin)
  * starts after first boot and guides new users through the configuration of the router
* monitoring of nodes through collectd
* some well known network-interfaces
  * "br-dhcp" for all client-traffic
  * "wlan0-adhoc-2" and "wlan1-adhoc-5" for AdHoc-meshing between nodes in 2.4GHz and 5GHz
  * "ffuplink" for all traffic sent via the uplink of the node-operator, in case "share traffic" is set up
    * freifunk-policyrouting fixed/patched for ffuplink-interface
* frei.funk as local DNS entry for your router
  * you do not have to remember your IP to get access
* change default lan ip address to 192.168.42.1/24
  * avoids network collisions
  * this is also used in OpenWrt failsafe
* one dhcp network for APs and lan (bridged)
* remove of autoipv6 and use of ULA ipv6 prefixes
* default dns servers:
  * 85.214.20.141 (FoeBud / Digital Courage)
  * 213.73.91.35 (CCC Berlin)
  * 194.150.168.168 (dns.as250.net)
  * 2001:4ce8::53 (as250)
  * 2001:910:800::12 (french data network - http://www.fdn.fr/)

## Contact / More information

The firmware wiki page is at: https://wiki.freifunk.net/Berlin:Firmware

For questions write a mail to <berlin@berlin.freifunk.net> or come to our weekly meetings.
If you find bugs please report them at: https://github.com/freifunk-berlin/firmware/issues

A tutorial on router configuration is available here (in German only):
http://berlin.freifunk.net/participate/howto/

## Development

### Info

For the Berlin Freifunk firmware we use vanilla OpenWrt with additional patches
and packages. The Makefile automates firmware
creation and apply patches / integrates custom freifunk packages. All custom
patches are located in *patches/* and all additional packages can be found at
http://github.com/freifunk-berlin/packages_berlin.

### Build Prerequisites

Please take a look at the [OpenWrt documentation](http://wiki.openwrt.org/doc/howto/buildroot.exigence#examples.of.package.installations)
for a complete and uptodate list of packages for your operating system. Make
sure the list contains `quilt`. We use it for patch management.

On Ubuntu/Debian:
```
apt-get install git build-essential libncurses5-dev zlib1g-dev gawk time \
  unzip libxml-perl flex wget gawk libncurses5-dev gettext quilt python libssl-dev
```

On openSUSE:
```
zypper install --type pattern devel_basis
zypper install git ncurses-devel zlib-devel gawk time \
  unzip perl-libxml-perl flex wget gawk gettext-runtime quilt python libopenssl-devel
```

### Building all firmwares

To get the source and build the firmware locally use:

```
git clone https://github.com/freifunk-berlin/firmware.git
cd firmware
make
```

The build will take some time. You can improve the build time with
[build options](http://wiki.openwrt.org/doc/howto/build#make_options) such as
`-j <number of cores>`. `V=s` will give more verbose error messages.

An internet connection is required during the build process. A good internet
connection can improve the build time.

You need approximately 10GB of space for the build.

### Directory Layout

You can find the actual firmware images generated by the ImageBuilder (and the ImageBuilder itself)
in `firmwares`. The layout looks like the following:

```
firmwares/
    TARGET/
        OpenWrt-ImageBuilder-....tar.bz2
        backbone/
           images..
        default/
           images..
        ...
        packages/
           base/
           luci/
           packages/
           packages_berlin/
           routing/
```

As you notice there are several different image variants ("backbone", "default", etc.).
These different *packages lists* are defined in `packages/`.
See the "Features" section above for a description of the purpose of each package list.

`make` will use by default `TARGET` and `PACKAGES_LIST_DEFAULT` defined in
`config.mk`. You can customize this by overriding them:

```
make TARGET=mpc85xx PACKAGES_LIST_DEFAULT=backbone
```
in addition you can build your own image from a prebuilt imagebuilder by something like:

```
make images IB_FILE=<file> TARGET=... PACKAGES_LIST_DEFAULT=...
```

The default target is `ar71xx-generic`. At the moment we support the following targets:

* ar71xx-generic
* ar71xx-mikrotik
* mpc85xx-generic
* ramips-mt7620
* ramips-mt7621
* x86-generic

You can find configs for these targets in `configs/`.

### Continuous integration / Buildbot

The firmware is [built
automatically](http://buildbot.berlin.freifunk.net/one_line_per_build) by our [buildbot farm](http://buildbot.berlin.freifunk.net/buildslaves). If you have a bit of CPU+RAM+storage capacity on one of your servers, you can provide a buildbot slave (see [berlin-buildbot](https://github.com/freifunk/berlin-buildbot)).

All branches whose name complies to the "X.Y.Z" pattern are built and put into the "stable" downloads directory:
[http://buildbot.berlin.freifunk.net/buildbot/stable/](http://buildbot.berlin.freifunk.net/buildbot/stable/)

All branches with names not fitting the "X.Y.Z" pattern are built and put into the "unstable" directory:
[http://buildbot.berlin.freifunk.net/buildbot/unstable/](http://buildbot.berlin.freifunk.net/buildbot/unstable/)
Note that in the directory there is no reference to the branch name; unstable builds can be identified by build number only.

#### Creating a release

Every release has a [semantic version number](http://semver.org); each major version has its own codename.
We name our releases after important female computer scientists, hackers, etc.
For inspiration please take a look at the related
[ticket](https://github.com/freifunk-berlin/firmware/issues/24).

For a new release, create a new branch. The branch name must be a semantic version
number. Make sure you change the semantic version number and, for major releases,
the codename in the README and config files (./configs/*)

The buildbot will build the release and place the files in the stable direcotry
once you pushed the new branch to github.

### Patches with quilt

**Important:** all patches should be pushed upstream!

If a patch is not yet included upstream, it can be placed in the `patches` directory with the `quilt` tool. Please configure `quilt` as described in the [OpenWrt wiki](http://wiki.openwrt.org/doc/devel/patches) (which also provides a documentation of `quilt`).

#### Add, modify or delete a patch

In order to add, modify or delete a patch run:

```bash
make clean pre-patch
```
Then switch to the openwrt directory:

```bash
cd openwrt
```
Now you can use the `quilt` commands as described in the [OpenWrt wiki](http://wiki.openwrt.org/doc/devel/patches).

##### Example: add a patch

```bash
quilt push -a                 # apply all patches
quilt new 008-awesome.patch   # tell quilt to create a new patch
quilt edit somedir/somefile1  # edit files
quilt edit somedir/somefile2
quilt refresh                 # creates/updates the patch file
```

### Submitting patches

#### Freifunk Berlin

Please create a pull request for the project you want to submit a patch.
If you are already member of the Freifunk Berlin team, please delete branches once they have been merged.

#### OpenWrt

Create a commit in the openwrt directory that contains your change. Use `git
format-patch` to create a patch:

```
git format-patch origin
```

Send a patch to the OpenWrt mailing list with `git send-email`:

```
git send-email \
  --to=openwrt-devel@lists.openwrt.org \
  --smtp-server=mail.foo.bar \
  --smtp-user=foo \
  --smtp-encryption=tls \
  0001-a-fancy-change.patch
```

Additional information: https://dev.openwrt.org/wiki/SubmittingPatches

