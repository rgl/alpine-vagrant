This builds an up-to-date Vagrant Alpine Linux Base Box.

Currently this targets [Alpine Linux](https://alpinelinux.org/) 3.10.


# Usage

Install [Packer](https://www.packer.io/), [Vagrant](https://www.vagrantup.com/) and [VirtualBox](https://www.virtualbox.org/).

Install the [vagrant-alpine](https://github.com/maier/vagrant-alpine) vagrant plugin:

```bash
vagrant plugin install vagrant-alpine
```

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

Type `make build-libvirt` and follow the instructions.

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


## VirtualBox usage

Install [VirtualBox](https://www.virtualbox.org/).

Type `make build-virtualbox` and follow the instructions.

Try the example guest:

```bash
cd example
vagrant up --provider=virtualbox
vagrant ssh
exit
vagrant destroy -f
```

# Packer boot_command

The following table describes the steps used to install Alpine Linux.

**NB** This Packer `boot_command` method of installation is quite brittle, if you are having trouble installing, try increasing the install wait timeout, or changing the [Alpine mirror](https://wiki.alpinelinux.org/wiki/Alpine_Linux:Mirrors) in the `answers` file to one near you.

| step                                   | boot_command                                                                    |
|---------------------------------------:|---------------------------------------------------------------------------------|
| login as root                          | `root<enter>`                                                                   |
| bring up the network                   | `ifconfig eth0 up && udhcpc -i eth0<enter><wait5>`                              |
| download the setup answers             | `wget -q http://{{.HTTPIP}}:{{.HTTPPort}}/answers<enter><wait>`                 |
| run the setup                          | `setup-alpine -f $PWD/answers<enter><wait5>`                                    |
| type the root password                 | `vagrant<enter>`                                                                |
| re-type the root password              | `vagrant<enter>`                                                                |
| wait for the services to start         | `<wait10><wait10><wait10>`                                                      |
| confirm that we want to erase sda      | `y<enter>`                                                                      |
| wait 1m for the installation to finish | `<wait10><wait10><wait10><wait10><wait10><wait10>`                              |
| mount the root partition               | `mount /dev/sda3 /mnt<enter>`                                                   |
| configure sshd to allow root login     | `sed -i -E 's,#?(PermitRootLogin\s+).+,\1yes,' /mnt/etc/ssh/sshd_config<enter>` |
| reboot to the installed system         | `reboot<enter>`                                                                 |

# Reference

* [Alpine setup scripts](https://wiki.alpinelinux.org/wiki/Alpine_setup_scripts)
