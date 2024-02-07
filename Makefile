VERSION=$(shell jq -r .variables.version alpine.json)

help:
	@echo type make build-libvirt, or build-uefi-libvirt

build-libvirt: alpine-${VERSION}-amd64-libvirt.box
build-uefi-libvirt: alpine-${VERSION}-uefi-amd64-libvirt.box

alpine-${VERSION}-amd64-libvirt.box: provision.sh alpine.json Vagrantfile.template
	rm -f $@
	PACKER_KEY_INTERVAL=10ms packer build -only=alpine-${VERSION}-amd64-libvirt -on-error=abort alpine.json
	@echo BOX successfully built!
	@echo to add to local vagrant install do:
	@echo vagrant box add -f alpine-${VERSION}-amd64 $@

alpine-${VERSION}-uefi-amd64-libvirt.box: provision.sh alpine.json Vagrantfile-uefi.template
	rm -f $@
	PACKER_KEY_INTERVAL=10ms packer build -only=alpine-${VERSION}-uefi-amd64-libvirt -on-error=abort alpine.json
	@echo BOX successfully built!
	@echo to add to local vagrant install do:
	@echo vagrant box add -f alpine-${VERSION}-uefi-amd64 $@

.PHONY: buid-libvirt buid-uefi-libvirt
