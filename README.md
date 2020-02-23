# Freifunk Berlin Firmware
https://wiki.freifunk.net/Berlin:Firmware

This is the build-system for the Firmware of Freifunk Berlin.
The firmware is based on vanilla [OpenWrt](https://openwrt.org/start) with some modifications (to fix
broken stuff in OpenWrt itself or for example LuCI) and additional default packages/configuration settings.

## Contact / More information

This branch is used to integrate the gluon-build-framework to out buildsystem. The intention
is based on:
* using "scripts/target_config.lua" 
* use the more flexible package-selection for kernel-packages as seen in "targets/ath79-generic"
* feature the flexible selection of finally published images (sysupgrade, factory, tftp, initrd)

