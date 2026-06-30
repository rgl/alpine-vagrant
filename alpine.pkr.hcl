packer {
  required_plugins {
    # see https://github.com/hashicorp/packer-plugin-qemu
    qemu = {
      version = "1.1.4"
      source  = "github.com/hashicorp/qemu"
    }
    # see https://github.com/hashicorp/packer-plugin-vagrant
    vagrant = {
      version = "1.1.7"
      source  = "github.com/hashicorp/vagrant"
    }
  }
}

variable "vagrant_box" {
  type = string
}

variable "version" {
  type    = string
  default = "3.24"
}

variable "iso_url" {
  type    = string
  default = "https://dl-cdn.alpinelinux.org/alpine/v3.24/releases/x86_64/alpine-standard-3.24.1-x86_64.iso"
}

variable "iso_checksum" {
  type    = string
  default = "sha256:f4dd613206676c62949144c8ad75fc64582099f444dd1485bae104a60f51dd26"
}

variable "disk_size" {
  type    = string
  default = 16 * 1024
}

source "qemu" "alpine-amd64" {
  accelerator  = "kvm"
  machine_type = "q35"
  cpus         = 2
  memory       = 2 * 1024
  qemuargs = [
    ["-cpu", "host"]
  ]
  headless       = true
  net_device     = "virtio-net"
  http_directory = "."
  format         = "qcow2"
  disk_size      = var.disk_size
  disk_interface = "virtio-scsi"
  disk_cache     = "unsafe"
  disk_discard   = "unmap"
  iso_url        = var.iso_url
  iso_checksum   = var.iso_checksum
  ssh_username   = "vagrant"
  ssh_password   = "vagrant"
  ssh_timeout    = "60m"
  boot_wait      = "30s"
  boot_command = [
    "root<enter>",
    "ifconfig eth0 up && udhcpc -i eth0<enter><wait5s>",
    "wget -qO- http://{{.HTTPIP}}:{{.HTTPPort}}/install.sh | ash<enter>"
  ]
  shutdown_command = "doas poweroff"
}

source "qemu" "alpine-uefi-amd64" {
  accelerator       = "kvm"
  machine_type      = "q35"
  efi_boot          = true
  efi_firmware_code = "/usr/share/OVMF/OVMF_CODE_4M.fd"
  efi_firmware_vars = "/usr/share/OVMF/OVMF_VARS_4M.fd"
  cpus              = 2
  memory            = 2 * 1024
  qemuargs = [
    ["-cpu", "host"],
  ]
  headless       = true
  net_device     = "virtio-net"
  http_directory = "."
  format         = "qcow2"
  disk_size      = var.disk_size
  disk_interface = "virtio-scsi"
  disk_cache     = "unsafe"
  disk_discard   = "unmap"
  iso_url        = var.iso_url
  iso_checksum   = var.iso_checksum
  ssh_username   = "vagrant"
  ssh_password   = "vagrant"
  ssh_timeout    = "60m"
  boot_wait      = "30s"
  boot_command = [
    "root<enter>",
    "ifconfig eth0 up && udhcpc -i eth0<enter><wait5s>",
    "wget -qO- http://{{.HTTPIP}}:{{.HTTPPort}}/install.sh | ash<enter>"
  ]
  shutdown_command = "doas poweroff"
}

build {
  sources = [
    "source.qemu.alpine-amd64",
    "source.qemu.alpine-uefi-amd64"
  ]

  provisioner "shell" {
    execute_command = "doas sh {{.Path}}"
    scripts         = ["provision.sh"]
  }

  post-processor "vagrant" {
    only = [
      "qemu.alpine-amd64",
    ]
    output               = var.vagrant_box
    vagrantfile_template = "Vagrantfile.template"
  }

  post-processor "vagrant" {
    only = [
      "qemu.alpine-uefi-amd64",
    ]
    output               = var.vagrant_box
    vagrantfile_template = "Vagrantfile-uefi.template"
  }
}
