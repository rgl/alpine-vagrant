This builds an up-to-date Vagrant Alpine Linux Base Box.

Currently this targets [Alpine Linux](https://alpinelinux.org/) 3.22.


# Usage

Install [Packer (1.13+)](https://www.packer.io/) and [Vagrant (2.4+)](https://www.vagrantup.com/).

If you are on a Debian/Ubuntu host, you should also install and configure the NFS server. E.g.:

```bash
# install the nfs server.
sudo apt-get install -y nfs-kernel-server

# enable password-less configuration of the nfs server exports.
sudo bash -c 'cat >/etc/sudoers.d/vagrant-synced-folders' <<'EOF'
Cmnd_Alias VAGRANT_EXPORTS_CHOWN = /bin/chown 0\:0 /tmp/*
Cmnd_Alias VAGRANT_EXPORTS_MV = /bin/mv -f /tmp/* /etc/exports
Cmnd_Alias VAGRANT_NFSD_CHECK = /etc/init.d/nfs-kernel-server status
Cmnd_Alias VAGRANT_NFSD_START = /etc/init.d/nfs-kernel-server start
Cmnd_Alias VAGRANT_NFSD_APPLY = /usr/sbin/exportfs -ar
%sudo ALL=(root) NOPASSWD: VAGRANT_EXPORTS_CHOWN, VAGRANT_EXPORTS_MV, VAGRANT_NFSD_CHECK, VAGRANT_NFSD_START, VAGRANT_NFSD_APPLY
EOF
```

For more information see the [Vagrant NFS documentation](https://www.vagrantup.com/docs/synced-folders/nfs.html).


## qemu-kvm usage

Install qemu-kvm:

```bash
apt-get install -y qemu-kvm
apt-get install -y sysfsutils
apt-get install -y rng-tools
systool -m kvm_intel -v
```

Build the box, and follow the printed instructions:

```bash
make build-libvirt
```

Try the example guest:

```bash
cd example
apt-get install -y virt-manager libvirt-dev
vagrant plugin install vagrant-libvirt
vagrant up --provider=libvirt
vagrant ssh
exit
vagrant destroy -f
```

# Packer boot_command

The following table describes the steps used to install Alpine Linux.

| step                 | boot_command                                                          |
|---------------------:|-----------------------------------------------------------------------|
| login as root        | `root<enter>`                                                         |
| bring up the network | `ifconfig eth0 up && udhcpc -i eth0<enter><wait5s>`                   |
| install              | `wget -qO- http://{{.HTTPIP}}:{{.HTTPPort}}/install.sh \| ash<enter>` |

# Reference

* [Alpine setup scripts](https://wiki.alpinelinux.org/wiki/Alpine_setup_scripts)
