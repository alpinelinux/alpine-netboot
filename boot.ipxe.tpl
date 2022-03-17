#!ipxe

set os Alpine Linux
iseq ${ipxe_cloud_config} packet && set provider (Packet.net) ||
iseq ${alpine_loader} true && set img_verify enabled || set img_verify disabled
set console tty0 ||
set cmdline {{{cmdline}}} ||
set default_cmdline default ||
set start_sshd no ||
set branch {{{default.branch}}} ||
set version {{{default.version}}} ||
set flavor {{{default.flavor}}} ||
iseq ${buildarch} arm64 && goto arm64 ||
cpuid --ext 29 && goto x86_64 || goto x86

:arm64
set arch aarch64 ||
set acpi acpi=force ||
set console ttyAMA0 ||
iseq ${ipxe_cloud_config} packet && set console ttyAMA0,115200 ||
goto menu

:x86_64
set arch x86_64 ||
iseq ${ipxe_cloud_config} packet && set console ttyS1,115200n8 ||
goto menu

:x86
set arch x86 ||
goto menu

:menu
set space:hex 20:20
set space ${space:string}
menu ${os} ${provider} [ ${arch} ]
item --gap Boot options
item branch ${space} Alpine version [ ${branch} ]
iseq ${arch} x86_64 && item flavor ${space} Kernel flavor [ ${flavor} ] ||
iseq ${alpine_loader} true && item img_verify ${space} Image verification [ ${img_verify} ] ||
item cmdline ${space} Linux cmdline [ ${default_cmdline} ]
item console ${space} Set console [ ${console} ]
item start_sshd ${space} Start sshd at first boot [ ${start_sshd} ]
item --gap Booting
item boot ${space} Boot with above settings
item --gap Utilities
item shell ${space} iPXE Shell
item reboot ${space} Reboot system
choose item
goto ${item}

:branch
menu ${os} ${provider} [ ${arch} ]
{{#releases}}
item {{{branch}}} Version {{{version}}}
{{/releases}}
choose branch || goto shell
{{#releases}}
iseq branch {{{branch}}} && set version {{{version}}} ||
{{/releases}}
goto menu

:flavor
menu ${os} ${provider} [ ${arch} ]
{{#flavors}}
item {{{.}}} Linux {{{.}}}
{{/flavors}}
choose flavor || goto shell
goto menu

:console
menu ${os} ${provider} [ ${arch} ]
{{#consoles}}
item {{{.}}} Console on {{{.}}}
{{/consoles}}
item custom Enter custom console
choose console || goto menu
iseq ${console} custom && goto custom_console ||
goto menu

:custom_console
clear console
echo -n Enter console: && read console
goto menu

:shell
echo Type "exit" to return to menu.
shell
goto menu

:img_verify
iseq ${img_verify} enabled && set img_verify disabled || set img_verify enabled
goto menu

:cmdline
echo -n Enter extra cmdline options:${space} && read cmdline
set default_cmdline modified
goto menu

:start_sshd
clear start_sshd
echo -n Enter url to ssh key:${space} && read ssh_key
isset ${ssh_key} && set start_sshd yes || set start_sshd no
iseq ${start_sshd} yes && set ssh_key ssh_key=${ssh_key} || clear ssh_key
goto menu

:boot
isset ${console} && set console console=${console} ||
set mirror {{{mirror}}}
set img-url ${mirror}/${branch}/releases/${arch}/netboot-${version}
set sig-url sigs/${branch}/${arch}/${version}
set repo-url ${mirror}/${branch}/main
set modloop-url ${img-url}/modloop-${flavor}
imgfree
kernel ${img-url}/vmlinuz-${flavor} ${cmdline} alpine_repo=${repo-url} modloop=${modloop-url} ${console} ${acpi} ${ssh_key} initrd=initramfs-${flavor}
initrd ${img-url}/initramfs-${flavor}
iseq ${img_verify} enabled && goto verify_img || goto no_img_verify
:verify_img
imgverify vmlinuz-${flavor} ${sig-url}/vmlinuz-${flavor}.sig
imgverify initramfs-${flavor} ${sig-url}/initramfs-${flavor}.sig
:no_img_verify
boot
goto alpine_exit

:reboot
reboot

:poweroff
poweroff

:alpine_exit
clear menu
exit 0
