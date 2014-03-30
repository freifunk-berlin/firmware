Freifunk Firmware Berlin
========================

For the Berlin Freifunk firmware we use vanilla OpenWRT with additional patches
and packages. The *scripts* dir has some util scripts to automate firmware
creation and apply patches / integrate custom freifunk packages. All custom
patches are located in *patches/* and all additional packages can be found at
http://github.com/freifunk/packages-berlin.

HowTo
-----

Build all images
```
$ mkdir firmware && cd firmware
$ git clone git@github.com:freifunk/firmware-berlin.git
```

Copy your config firmware
```
$ cp firmware-berlin/default.config config
  or
$ cp firmware-berlin/configs/<target>.config config
```

Build
```
$ firmware-berlin/scripts/update-build.sh   # this step will take ages...
```

Build one packages
```
$ firmware-berlin/scripts/update-build-pkg.sh <packet-name>
```


Build ImageBuilders (to use in meshkit)
```
$ firmware-berlin/scripts/update-wib.sh
```


Add your own Package
--------------------

Create feeds package dir
```
$ cd firmware-berlin
$ mkdir -p feeds/my-package
```

Create a OpenWRT Makefile see http://wiki.openwrt.org/doc/devel/packages
```
$ nano feeds/my-package/Makefile
```

Add the "my-package" y|m Build-In or Modul (opkg) to config
```
$ echo 'make_options=$make_options" CONFIG_PACKAGE_my-package=m"' >> config
```

Build your images
```
$ firmware-berlin/scripts/update-build.sh
```
