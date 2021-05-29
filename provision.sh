#!/bin/ash
# abort this script when a command fails or a unset variable is used.
set -eu
# echo all the executed commands.
set -x

# upgrade all packages.
apk upgrade -U --available

# add the vagrant user and let it use root permissions without sudo asking for a password.
apk add sudo
adduser -D vagrant
echo 'vagrant:vagrant' | chpasswd
adduser vagrant wheel
echo '%wheel ALL=(ALL) NOPASSWD:ALL' >/etc/sudoers.d/wheel

# add support for validating https certificates.
apk add ca-certificates openssl

# install the vagrant public key.
# NB vagrant will replace it on the first run.
install -d -m 700 /home/vagrant/.ssh
wget -qO /home/vagrant/.ssh/authorized_keys https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub
chmod 600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant:vagrant /home/vagrant/.ssh

# install the Guest Additions.
if [ "$(cat /sys/devices/virtual/dmi/id/board_name)" == 'VirtualBox' ]; then
# install the VirtualBox Guest Additions.
echo http://mirrors.dotsrc.org/alpine/v3.12/community >>/etc/apk/repositories
apk add -U virtualbox-guest-additions virtualbox-guest-modules-lts
rc-update add virtualbox-guest-additions
echo vboxsf >>/etc/modules
modinfo vboxguest
else
# install the qemu-kvm Guest Additions.
echo http://mirrors.dotsrc.org/alpine/v3.12/community >>/etc/apk/repositories
apk add -U qemu-guest-agent
rc-update add qemu-guest-agent
# configure the GA_PATH, as, for some reason, its at /dev/vport0p1 instead of
# the expected /dev/virtio-ports/org.qemu.guest_agent.0.
# NB from the host, you can test whether qemu-ga is running on the guest with:
#       virsh qemu-agent-command $(cat .vagrant/machines/default/libvirt/id) '{"execute":"guest-ping"}' | jq
#       virsh qemu-agent-command $(cat .vagrant/machines/default/libvirt/id) '{"execute":"guest-info"}' | jq
sed -i -E 's,#?(GA_PATH=).+,\1"/dev/vport0p1",' /etc/conf.d/qemu-guest-agent
fi

# install the nfs client to support nfs synced folders in vagrant.
apk add nfs-utils

# disable the DNS reverse lookup on the SSH server. this stops it from
# trying to resolve the client IP address into a DNS domain name, which
# is kinda slow and does not normally work when running inside VB.
sed -i -E 's,#?(UseDNS\s+).+,\1no,' /etc/ssh/sshd_config

# use the up/down arrows to navigate the bash history.
# NB to get these codes, press ctrl+v then the key combination you want.
cat >>/etc/inputrc <<'EOF'
"\e[A": history-search-backward
"\e[B": history-search-forward
set show-all-if-ambiguous on
set completion-ignore-case on
EOF

# zero the free disk space -- for better compression of the box file.
# NB prefer discard/trim (safer; faster) over creating a big zero filled file
#    (somewhat unsafe as it has to fill the entire disk, which might trigger
#    a disk (near) full alarm; slower; slightly better compression).
apk add util-linux
root_dev="$(findmnt -no SOURCE /)"
if [ "$(lsblk -no DISC-GRAN $root_dev | awk '{print $1}')" != '0B' ]; then
    while true; do
        output="$(fstrim -v /)"
        sync && sync && sync && blockdev --flushbufs $root_dev && sleep 15
        if [ "$output" == '/: 0 B (0 bytes) trimmed' ]; then
            break
        fi
    done
else
    dd if=/dev/zero of=/EMPTY bs=1M || true && sync && rm -f /EMPTY && sync
fi
