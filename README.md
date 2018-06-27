# Alpine Linux netboot

Welcome to the Alpine Linux netboot server.

This netboot server provides a boot script and image signatures to securly boot
Alpine Linux over the internet. To be able to boot you will need to have a copy
of the iPXE bootloader available. You can get a copy of the bootloaders by
installing alpine-ipxe `apk add alpine-ipxe` or from [this location](alpine-ipxe)
(only x86_64).

## Boot script

The default bootscript for alpine-ipxe is
**[https://boot.alpinelinux.org/boot.ipxe](boot.ipxe)** which will automatically
be fetched by alpine-ipxe. If you like to change this behaviour you will need to
build your own version of [ipxe](https://ipxe.org).

Some cloud providers (ie [packet.net](https://help.packet.net/technical/infrastructure/custom-ipxe))
support the loading of custom ipxe scripts/payloads to install an operating
system. You can chainload one of the ipxe bootloaders from [alpine-ipxe](alpine-ipxe).
Loading our boot script from another bootloader will disable image verification.

## Images

**NOTE**: since Alpine v3.8 this netboot server does not provide images anymore.
You can find netboot images in the release directories on our [mirrors](https://mirrors.alpinelinux.org).

## Signed images

Alpine Linux images are signed and can be verified only by making use of
[alpine-ipxe](alpine-ipxe). Using another ipxe bootloader will disable verification.

## Boot options

### BIOS (x86_64)

* [pxe.lkrn](alpine-ipxe/x86_64/ipxe.lkrn) - Linux kernel image that can be used by a bootloader/qemu
* [pxe.pxe](alpine-ipxe/x86_64/ipxe.pxe) - PXE image for chainloading from a PXE environment
* [undionly.kpxe](alpine-ipxe/x86_64/undionly.kpxe) - PXE image with UNDI support
* [ipxe.iso](alpine-ipxe/x86_64/ipxe.iso) - ISO image to boot from any regular system
* [ipxe.usb](alpine-ipxe/x86_64/ipxe.usb) - disk image to write to (USB) block device

### UEFI (x86_64)

* [ipxe.efi](alpine-ipxe/x86_64/ipxe.efi) UEFI executable

### UEFI (aarch64)

* snp.efi UEFI executable

## Updates

Currently we only support latest stable releases. We are working on adding montly
edge snapshots.

## Testing netboot

The easiest way to test is by using Qemu directly with the ipxe kernel image.

`apk add qemu-system-x86_64 alpine-ipxe`

`qemu-system-x86_64 -m 512M -enable-kvm -kernel /usr/share/alpine-ipxe/ipxe.lkrn -curses`

**NOTE**: you need a minimum of 256M of memory to boot alpine in network mode
due to the size of our initramfs and modloop (kernel modules).
