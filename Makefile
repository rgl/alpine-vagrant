SHELL=bash
.SHELLFLAGS=-euo pipefail -c

VERSION=3.24

export CHECKPOINT_DISABLE=1

help:
	@echo type make build-libvirt, or build-uefi-libvirt

build-libvirt: alpine-${VERSION}-amd64-libvirt.box
build-uefi-libvirt: alpine-${VERSION}-uefi-amd64-libvirt.box

alpine-${VERSION}-amd64-libvirt.box: provision.sh alpine.pkr.hcl Vagrantfile.template
	rm -f $@
	packer init alpine.pkr.hcl
	PKR_VAR_version=${VERSION} \
	PKR_VAR_vagrant_box=$@ \
	PACKER_KEY_INTERVAL=10ms \
		packer build \
			-only=qemu.alpine-amd64 \
			-on-error=abort \
			-timestamp-ui \
			alpine.pkr.hcl
	@./box-metadata.sh libvirt alpine-${VERSION}-amd64 $@

alpine-${VERSION}-uefi-amd64-libvirt.box: provision.sh alpine.pkr.hcl Vagrantfile-uefi.template
	rm -f $@
	packer init alpine.pkr.hcl
	PKR_VAR_version=${VERSION} \
	PKR_VAR_vagrant_box=$@ \
	PACKER_KEY_INTERVAL=10ms \
		packer build \
			-only=qemu.alpine-uefi-amd64 \
			-on-error=abort \
			-timestamp-ui \
			alpine.pkr.hcl
	@./box-metadata.sh libvirt alpine-${VERSION}-uefi-amd64 $@

.PHONY: buid-libvirt buid-uefi-libvirt
