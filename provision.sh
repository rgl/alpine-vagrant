#!/bin/ash
set -euxo pipefail

# upgrade all packages.
apk upgrade -U --available

# setup the console keymap (keyboard layout).
# NB this is also in the answers file (but with the us keymap).
setup-keymap pt pt

# install the doas sudo shim.
apk add doas-sudo-shim

# add support for validating https certificates.
apk add ca-certificates openssl

# install the vagrant public key.
# NB vagrant will replace it on the first run.
install -d -m 700 /home/vagrant/.ssh
wget -qO /home/vagrant/.ssh/authorized_keys https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub
chmod 600 /home/vagrant/.ssh/authorized_keys
chown -R vagrant:vagrant /home/vagrant/.ssh

# install the qemu-kvm Guest Additions.
echo http://mirrors.dotsrc.org/alpine/v3.20/community >>/etc/apk/repositories
apk add -U qemu-guest-agent
rc-update add qemu-guest-agent
# configure the GA_PATH, as, for some reason, its at /dev/vport0p1 instead of
# the expected /dev/virtio-ports/org.qemu.guest_agent.0.
# NB from the host, you can test whether qemu-ga is running on the guest with:
#       virsh qemu-agent-command $(cat .vagrant/machines/default/libvirt/id) '{"execute":"guest-ping"}' | jq
#       virsh qemu-agent-command $(cat .vagrant/machines/default/libvirt/id) '{"execute":"guest-info"}' | jq
sed -i -E 's,#?(GA_PATH=).+,\1"/dev/vport0p1",' /etc/conf.d/qemu-guest-agent

# install the nfs client to support nfs synced folders in vagrant.
apk add nfs-utils

# install vim.
apk add vim

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

# setup the shell profile.
cat >/etc/profile.d/login.sh <<'EOF'
export EDITOR=vim
export PAGER=less
alias l='ls -lF --color'
alias ll='l -a'
alias h='history 25'
alias j='jobs -l'
EOF

# zero the free disk space -- for better compression of the box file.
# NB prefer discard/trim (safer; faster) over creating a big zero filled file
#    (somewhat unsafe as it has to fill the entire disk, which might trigger
#    a disk (near) full alarm; slower; slightly better compression).
apk add util-linux
if [ "$(lsblk -no DISC-GRAN $(findmnt -no SOURCE /) | awk '{print $1}')" != '0B' ]; then
    while true; do
        output="$(fstrim -v /)"
        sync && sync && sleep 15
        bytes_trimmed="$(echo "$output" | awk '{match($0, /\([0-9]+ bytes\)/); if(RSTART) print substr($0, RSTART+1, RLENGTH-8)}')"
        # NB if this never reaches zero, it might be because there is not
        #    enough free space for completing the trim.
        if [ "$bytes_trimmed" -lt "$((200*1024*1024))" ]; then # < 200 MiB is good enough.
            break
        fi
    done
else
    dd if=/dev/zero of=/EMPTY bs=1M || true && sync && rm -f /EMPTY && sync
fi
