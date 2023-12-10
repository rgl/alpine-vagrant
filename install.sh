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
APKREPOSOPTS="http://mirrors.dotsrc.org/alpine/v3.19/main"
USEROPTS="-a vagrant"
SSHDOPTS="-c openssh"
NTPOPTS="-c chrony"
DISKOPTS="-s 0 -m sys $boot_device"
EOF
ERASE_DISKS="$boot_device" setup-alpine -e -f $PWD/answers

# reset the uefi boot options.
if [ "$firmware" == 'uefi' ]; then
  # install the efi boot manager.
  apk add efibootmgr
  # show the boot options.
  efibootmgr -v
  # remove all the boot options.
  efibootmgr \
    | sed -nE 's,^Boot([0-9A-F]{4}).*,\1,gp' \
    | xargs -I% efibootmgr --quiet --delete-bootnum --bootnum %
  # create the boot option.
  # NB if we do not set any boot option, the firmware will recover/discover them
  #    at the next boot. the firmware will find the shimx64.efi. when the shim
  #    runs for the first time in a system with an enabled TPM, it will do an
  #    extra reboot. when we are connected to the machine using AMT Remote
  #    Desktop, that extra reboot messes with the ethernet speed by switching it
  #    to a crawling 10 Mbps. to prevent all this we have to create this boot
  #    option.
  #    see https://github.com/coreos/fedora-coreos-tracker/issues/563
  #    see https://github.com/rhboot/shim
  efibootmgr \
    -c \
    -d "$boot_device" \
    -p 1 \
    -L Alpine \
    -l '\EFI\alpine\grubx64.efi'
fi

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

# lock the root account.
chroot /mnt passwd -l root

# reboot to the installed system.
reboot
