# Freifunk Berlin Firmware
https://wiki.freifunk.net/Berlin:Firmware

This is the build-system for the Firmware of Freifunk Berlin.
The firmware is based on vanilla [OpenWrt](https://openwrt.org/start) with some modifications (to fix
broken stuff in OpenWrt itself or for example LuCI) and additional default packages/configuration settings.

## Contact / More information

More user relevant information about the firmware are on the wiki page at: https://wiki.freifunk.net/Berlin:Firmware. There you can also find the
* [ReleaseNotes](https://wiki.freifunk.net/Berlin:Firmware/v1.0.2)
* a tutorial ([en](https://wiki.freifunk.net/Berlin:Firmware:En:Howto) / [de](https://wiki.freifunk.net/Berlin:Firmware:Howto)) on router configuration

For questions write a mail to <berlin@berlin.freifunk.net>, open a discussion with 
@freifunk-berlin/firmware or come to our weekly meetings.
If you find bugs please report them at: https://github.com/freifunk-berlin/firmware/issues

## Development

### Info

For the Berlin Freifunk firmware we use vanilla OpenWrt with additional patches
and packages. The Makefile automates firmware
creation and apply patches / integrates custom freifunk packages. All custom
patches are located in *patches/* and all additional packages can be found at
http://github.com/freifunk-berlin/packages_berlin.

### Build Prerequisites

Please take a look at the [OpenWrt documentation](https://openwrt.org/docs/guide-developer/build-system/install-buildsystem?s[]=prerequisites#prerequisites)
for a complete and uptodate list of packages for your operating system. 

On Ubuntu/Debian:
```
apt-get install git build-essential libncurses5-dev zlib1g-dev gawk time \
  unzip libxml-perl flex wget gawk gettext quilt python libssl-dev
```

On openSUSE:
```
zypper install --type pattern devel_basis
zypper install git ncurses-devel zlib-devel gawk time \
  unzip perl-libxml-perl flex wget gawk gettext-runtime quilt python libopenssl-devel
```
On Arch/Antergos:
```
pacman -S base-devel git ncurses lib32-zlib gawk time unzip perl-xml-libxml \
 flex wget gettext quilt python2 openssl
```

### Building all firmwares

To get the source and build the firmware locally use:

```
git clone https://github.com/freifunk-berlin/firmware.git
cd firmware
make
```

The build will take some time. You can improve the build time with [build options](https://openwrt.org/docs/guide-developer/build-system/use-buildsystem)
such as `-j <number of cores>`. `V=s` will give more verbose error messages.

An internet connection is required during the build process. A good internet
connection can improve the build time.

You need approximately 10GB of space for the build.

### Building individual packages

To develop on a single package or to compile a special package, which is not available by default
on OpenWrt or Freifunk-Berlin, you can use the SDK. The prebuilt SDK of the firmware you are 
running on can be found in the TARGETS root-folder.

To build your own package with the SDK do the following:

```
(cd /tmp; wget https://firmware.berlin...SDK*.tar.xz)
git clone https://github.com/freifunk-berlin/firmware.git
cd firmware
make setup-sdk SDK_FILE=/tmp/<SDK-file from above>
cd sdk-<target>
```

This folder represents the environment, that was used during building the firmware, including all
patches. You can customize the environment, install feeds and packages and update the existing
code.
To build a single package use the normal OpwnWrt command:

```
make package/freifunk-berlin-ffwizard/compile
```

### Directory Layout

You can find the actual firmware images generated by the ImageBuilder (and the ImageBuilder itself)
in `firmwares`. The layout looks like the following:

```
firmwares/
    TARGET/
        backbone/
           images..
        default/
           images..
        ...
        OpenWrt-ImageBuilder-....tar.xz
        OpenWrt-SDK-....tar.xz
        initrd/
           images..
        packages/
           packages/<ARCH>
              base/*.ipk
              luci/*.ipk
              packages/*.ipk
              packages_berlin/*.ipk
              routing/*.ipk
           targets/MAINTARGET/SUBTARGET/packages/
              *.ipk
```

As you notice there are several different image variants ("backbone", "default", etc.).
These different *packages lists* are defined in `packages/`.
See the "Features" section above for a description of the purpose of each package list.
With the "OpenWrt-Imagebuilder" you can assemble your own image variant with your
*packages lists* without having to compile everything yourself. The "OpenWrt-SDK" is
the fastest way to build your own packages or programs without compiling OpenWrt itself.
The "initrd" directory contains some initrd-images for netboot, which are required on
some boards to initially install OpenWrt.

### customizing make

`make` will use by default `TARGET` and `PACKAGES_LIST_DEFAULT` defined in
`config.mk`. You can customize this by overriding them:

```
make TARGET=mpc85xx PACKAGES_LIST_DEFAULT=backbone
```
in addition you can build your own image from a prebuilt imagebuilder by something like:

```
make images IB_FILE=<file> TARGET=... PACKAGES_LIST_DEFAULT=...
```

The default target is `ar71xx-generic`. For a complete list of supported targets look in `configs/` for the target-specific configs.
Each of these targets need a matching file in `profiles/` with the profiles (boards) that should be build with the imagebuilder.

### Continuous integration / GitHubActions

The firmware is [built
automatically](https://github.com/freifunk-berlin/firmware/actions) via a [GitHubActions workflow](https://github.com/freifunk-berlin/firmware/blob/master/.github/workflows/build-firmware.yml). A build is triggered by any PR or commit to the master branch. We switched from a selfhosted [Buildbot-setup](https://buildbot.net/) to GitHubActions to reduce the maintenance we need.

Since the switch to GitHubActions nobody reimplemented a way of deploying / publishing the builds, so the following sentences are just some kind of reminder for this ToDo.

~~All branches whose name complies to the "X.Y.Z" pattern are built and put into the "stable" downloads directory:
[http://buildbot.berlin.freifunk.net/buildbot/stable/](http://buildbot.berlin.freifunk.net/buildbot/stable/)~~

~~All branches with names not fitting the "X.Y.Z" pattern are built and put into the "unstable" directory:
[http://buildbot.berlin.freifunk.net/buildbot/unstable/](http://buildbot.berlin.freifunk.net/buildbot/unstable/)
Note that in the directory there is no reference to the branch name; unstable builds can be identified by build number only.~~

#### Creating a release

Every release has a [semantic version number](http://semver.org); each major version has its own codename.
We name our releases after important female computer scientists, hackers, etc.
For inspiration please take a look at the related
[ticket](https://github.com/freifunk-berlin/firmware/issues/24).

For a new release, create a new branch. The branch name must be a semantic version
number. Make sure you change the semantic version number and, for major releases,
the codename in the README and config files (./configs/*)

~~The buildbot will build the release and place the files in the stable direcotry
once you pushed the new branch to github.~~

### Patches with "git format-patch"

**Important:** all patches should be pushed upstream!

If a patch is not yet included upstream, it can be placed in the corresponding subdirectory below the `patches`
directory. To create a correct patch-file just use the `make update-patches` command. It's a wrapper around 
[`git format-patch`](https://git-scm.com/docs/git-format-patch) to transform local-changes into .patch files.
This wrapper is borrowed from the [Freifunk Gluon buildsystem](https://github.com/freifunk-gluon/gluon), so 
check their [documentation](https://gluon.readthedocs.io/en/latest/dev/basics.html#working-with-repositories).

#### Create a patch

In order to add a patch file update your build environment by running:

```bash
make clean patch
```
Then switch to the openwrt directory:

```bash
cd openwrt
```
or continue to the relevant feed directory:

```bash
cd feeds/luci
```
use the normal `git commit` workflow to apply your changes to the code of the `patched` branch. When done convert
change back to the root folder and run:

```bash
make update-patches
```
This will update all patches and show the changes by `git status patches/`. Mannually review them and commit the requred
changes. Your new patch should show up as an untracked file in the relating subfolder.

#### Modify a patch

To update an existing patch do the same as above:

```bash
make clean patch
cd openwrt
cd feeds/luci
```
Then just add a new commit with your changes and squash it or rebase it to the originating commit. To update the 
patch-file use the same `make update-patches` sequence as you did when creating the patch initially.

By squashing / rebasing you ensure, that your changes will not become a separate patch-file, but stays just a clean
patch-file.

#### Delete a patch

To remove a patch-file you have to remove it from the patch-subdirectory and update the build-
environment:

```bash
git rm patches/openwrt/0010-unrelevant-change.patch
make update-patches
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
