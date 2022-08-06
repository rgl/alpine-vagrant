#!/bin/ash
set -euxo pipefail

firmware="$([ -d /sys/firmware/efi ] && echo 'uefi' || echo 'bios')"
boot_device='/dev/sda'

# install to local disk.
cat >answers <<EOF
KEYMAPOPTS="us us"
HOSTNAMEOPTS="-n alpine"
INTERFACESOPTS="auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
"
DNSOPTS=""
TIMEZONEOPTS="-z UTC"
PROXYOPTS="none"
APKREPOSOPTS="http://mirrors.dotsrc.org/alpine/v3.16/main"
USEROPTS="-a vagrant"
SSHDOPTS="-c openssh"
NTPOPTS="-c chrony"
DISKOPTS="-s 0 -m sys $boot_device"
EOF
ERASE_DISKS="$boot_device" setup-alpine -e -f $PWD/answers

# configure the vagrant user.
mount "${boot_device}2" /mnt
chroot /mnt ash <<'EOF'
set -euxo pipefail

# configure doas to allow the wheel group members to use root permissions
# without providing a password.
echo 'permit nopass :wheel' >/etc/doas.d/wheel.conf

# set the vagrant user password.
echo 'vagrant:vagrant' | chpasswd
EOF

# force the firmware to boot from disk.
if [ "$firmware" == 'uefi' ]; then
    apk add efibootmgr
    efibootmgr -o 0002
fi

# lock the root account.
chroot /mnt passwd -l root

# reboot to the installed system.
reboot
