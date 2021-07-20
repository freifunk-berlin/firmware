# Freifunk Berlin Firmware
https://wiki.freifunk.net/Berlin:Firmware

This is the build system for the firmware of Freifunk Berlin.
The firmware is based on vanilla [OpenWrt](https://openwrt.org/start) with some modifications (to fix
broken stuff in OpenWrt itself or for example LuCI) and additional default packages/configuration settings.

## Contact / More information

More user-relevant information on the firmware can be found on the wiki page at: https://wiki.freifunk.net/Berlin:Firmware. There you can also find the
* [Release Notes](https://wiki.freifunk.net/Berlin:Firmware/v1.0.2)
* a tutorial ([en](https://wiki.freifunk.net/Berlin:Firmware:En:Howto) / [de](https://wiki.freifunk.net/Berlin:Firmware:Howto)) on router configuration

If you have any questions, send an email to <berlin@berlin.freifunk.net>, open a discussion with 
@freifunk-berlin/firmware or come to our weekly meetings.
If you find bugs, please report them at: https://github.com/freifunk-berlin/firmware/issues

## Development

### Info

For the Berlin Freifunk firmware we use vanilla OpenWrt with additional patches and packages.
The Makefile automates the build of the firmware (applies patches, integrates custom packages and uses the
the ImageBuilder of OpenWrt).

The idea is to download OpenWrt via git, patch it with all patches in the `patches/` folder
patch it and configure it according to the configuration snippets in `configs/`. Then use the OpenWrt
build system to build all packages and the image builder. The packages that will be assembled to the final image for the router
image for the router are taken from the image flavors defined in `packagelist/`.

### Build prerequisites

Please take a look at the [OpenWrt documentation](https://openwrt.org/docs/guide-developer/build-system/install-buildsystem?s[]=prerequisites#prerequisites)
for a complete and up-to-date list of packages for your operating system. 

Alpine:
```
apk add asciidoc bash bc binutils bzip2 cdrkit coreutils diffutils \
findutils flex g++ gawk gcc gettext git grep intltool libxslt \
linux-headers make ncurses-dev openssl-dev patch perl \
python2-dev python3-dev rsync tar unzip util-linux wget zlib-dev
```

Arch / Manjaro:
```
# Essential prerequisites
pacman -S --needed base-devel bash bzip2 git libelf libxslt ncurses \
openssl python2 time unzip util-linux wget zlib
 
# Optional prerequisites, depend on the package selection
pacman -S --needed asciidoc help2man intltool perl-extutils-makemaker
```

CentOS / Fedora:
```
sudo dnf --skip-broken install bash-completion bzip2 gcc gcc-c++ git \
make ncurses-devel patch perl-Data-Dumper perl-Thread-Queue python2 \
python3 rsync tar unzip wget perl-base perl-File-Compare \
perl-File-Copy perl-FindBin diffutils which
```

Debian / Ubuntu:
```
sudo apt install build-essential ccache ecj fastjar file g++ gawk \
gettext git java-propose-classpath libelf-dev libncurses5-dev \
libncursesw5-dev libssl-dev python python2.7-dev python3 unzip wget \
python3-distutils python3-setuptools python3-dev rsync subversion swig time \
xsltproc zlib1g-dev 
```

Gentoo:
```
echo \
app-arch/{bzip2,sharutils,unzip,zip} sys-process/time \
app-text/asciidoc \
dev-libs/{libusb-compat,libxslt,openssl} dev-util/intltool \
dev-vcs/{git,mercurial} net-misc/{rsync,wget} \
sys-apps/util-linux sys-devel/{bc,bin86,dev86} \
sys-libs/{ncurses,zlib} virtual/perl-ExtUtils-MakeMaker \
| sed "s/\s/\n/g" \
| sort \
| sudo tee /etc/portage/sets/openwrt-prerequisites \
&& sudo emerge -DuvNa "@openwrt-prerequisites"
```

On openSUSE:
```
sudo zypper install --no-recommends asciidoc bash bc binutils bzip2 \
fastjar flex gawk gcc gcc-c++ gettext-tools git git-core intltool \
libopenssl-devel libxslt-tools make mercurial ncurses-devel patch \
perl-ExtUtils-MakeMaker python-devel rsync sdcc unzip util-linux \
wget zlib-devel
```

### Building the firmware for all targets

To get the source code and build the firmware locally, use:

```
git clone https://github.com/freifunk-berlin/firmware.git
cd firmware
make
```

The build will take some time. You can improve the build time with [build options](https://openwrt.org/docs/guide-developer/build-system/use-buildsystem)
such as `-j <number of cores>`. With `V=s` more detailed error messages are output.

An internet connection is required during the build process. A good internet
connection can improve the build time.

You will need about 10 GB of disk space for the build.

### Building individual packages

To develop on a single package or to compile a special package that is not available by default on OpenWrt or Freifunk-Berlin, you can use the SDK.
The precompiled SDK of the firmware you are using can be found in the root directory TARGETS.

To build your own package using the SDK, follow these steps:

```
(cd /tmp; wget https://firmware.berlin...SDK*.tar.xz)
git clone https://github.com/freifunk-berlin/firmware.git
cd firmware
make setup-sdk SDK_FILE=/tmp/<SDK-file from above>
cd sdk-<target>
```

This folder represents the environment that was used to create the firmware, including any
patches. You can customize the environment, install feeds and packages, and modify the existing
code.
To build a single package, use the normal OpwnWrt command:

```
make package/freifunk-berlin-ffwizard/compile
```

### Directory layout

The actual firmware images generated by the ImageBuilder (and the ImageBuilder itself) can be found
in `firmwares`. The layout looks like this:

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

As you notice, there are several different image variants ("backbone", "default", etc.).
These different *package lists* are defined in `packages/`.
For a description of the purpose of each package list, see the "Features" section above.
With the "OpenWrt-ImageBuilder" you can assemble your own image variant with your
*package lists* without having to compile everything yourself. The "OpenWrt-SDK" is
the fastest way to build your own packages or programs without compiling OpenWrt yourself.
The "initrd" directory contains some initrd images for netboot, which are used on
some boards for the initial installation of OpenWrt.

### Customizing make

By default `make` uses `TARGET` and `PACKAGES_LIST_DEFAULT` which are defined in
`config.mk`. You can customize this by overriding them:

```
make TARGET=mpc85xx PACKAGES_LIST_DEFAULT=backbone
```
Additionally, you can create your own image from a pre-built ImageBuilder by doing something like:

```
make images IB_FILE=<file> TARGET=... PACKAGES_LIST_DEFAULT=...
```

The default target is `ar71xx-generic`. For a complete list of supported targets, see the `configs/` directory for target-specific configurations.
Each of these targets needs a matching file in `profiles/` with the profiles (boards) to be built with ImageBuilder.

### Build system structure

Where can I change something? What are these files for?

```
config.mk                    - Generic build parameters, default target to build, choose which
                               package lists should be built
modules                      - Defines all external repositories to be used
                               (see https://gluon.readthedocs.io/en/latest/dev/build.html#feed-management)
configs/                     - Target-specific configuration snippets that are passed to the OpenWrt build system
  common.config              - OpenWrt configuration parameters for all targets
  $(TARGET).config           - Target specific configuration. Will be added to common.config.
                               Options from target.config override those from common.config.
  common-autobuild.config    - Added on top when building with Makefile.autobuild.
patches/                     - Patches against OpenWrt / individual feeds
  openwrt                    - Patches for OpenWrt-core
  packages/$(FEED)           - Patches for each feed used (closely related to the definitions in modules).
packagelists/                - Package lists 
  profile-packages.txt       - Allows you to specify packets on a per-router basis. Allows adding and removing
                               packages defined in the default OpenWrt list and in our package list.
profiles/                    - List of router profiles for each target - profile names correspond to OpenWrt
                               board definition
Makefile                     - Does all the stuff. Cloning and updating OpenWrt, patching, running make.
Makefile.autobuild           - Slightly reduced Makefile for CI builds (more granular steps, ...)
scripts/assemble_firmware.sh - Script to run the ImageBuilder for a target
```

### Continuous integration / GitHub Actions

The firmware is [built
automatically](https://github.com/freifunk-berlin/firmware/actions) via a [GitHub Actions workflow](https://github.com/freifunk-berlin/firmware/blob/master/.github/workflows/build-firmware.yml). 
A build is triggered by any PR or commit to the master branch.

#### Creating a release

Each release has a [semantic version number] (https://semver.org/); each major release has its own code name.
We name our releases after important computer scientists, hackers, etc.
For inspiration, please see the related
[ticket](https://github.com/freifunk-berlin/firmware/issues/24).

A new branch must be created for a new release. The branch name must be a semantic version number.
Make sure that you include the semantic version number and, for major releases
the codename in the README and configuration files (./configs/*).

### Patches with "git format-patch"

**Important:** All patches should be pushed upstream!

If a patch is not yet included in the upstream, it can be placed in the appropriate subdirectory below the `patches`
directory. To create a correct patch file, simply use the `make update-patches` command. It is a wrapper around 
[`git format-patch`](https://git-scm.com/docs/git-format-patch) to convert local changes to .patch files.
This wrapper is borrowed from the [Freifunk Gluon build system](https://github.com/freifunk-gluon/gluon), so 
have a look at their [documentation](https://gluon.readthedocs.io/en/latest/dev/basics.html#working-with-repositories).

#### Creating a patch

To add a patch file, update your build environment by running:

```bash
make clean patch
```
Then switch to the OpenWrt directory:

```bash
cd openwrt
```
or continue to the respective feed directory:

```bash
cd feeds/luci
```
use the normal `git commit` workflow to apply your changes to the code of the `patched` branch. When you are done,
switch back to the root folder and run:

```bash
make update-patches
```
This will update all patches and show the changes through `git status patches/`. Check them manually and commit the required
changes. Your new patch should show up as an untracked file in the appropriate subfolder.

#### Modifying a patch

To update an existing patch, proceed as described above:

```bash
make clean patch
cd openwrt
cd feeds/luci
```
Then simply add a new commit with your changes and squash it or rebase it to the original commit. To update the 
patch file, use the same `make update-patches` sequence as when you initially created the patch.

By squashing / rebasing you ensure that your changes do not become a separate patch file, but stay in a clean patch file.

#### Deleting a patch

To remove a patch file, you must remove it from the patch subdirectory and update the build environment:

```bash
git rm patches/openwrt/0010-unrelevant-change.patch
make update-patches
```

### Submitting patches

#### Freifunk Berlin

Please create a pull request for the project you want to submit a patch for.
If you are already a member of the Freifunk Berlin team, please delete branches once they have been merged.

#### OpenWrt

Create a commit in the OpenWrt directory that contains your change. Use `git
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

Additional information: https://openwrt.org/submitting-patches
