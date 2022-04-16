VERSION=$(shell jq -r .variables.version alpine.json)

help:
	@echo type make build-libvirt, build-uefi-libvirt, or make build-virtualbox

build-libvirt: alpine-${VERSION}-amd64-libvirt.box
build-uefi-libvirt: alpine-${VERSION}-uefi-amd64-libvirt.box

build-virtualbox: alpine-${VERSION}-amd64-virtualbox.box

alpine-${VERSION}-amd64-libvirt.box: answers provision.sh alpine.json Vagrantfile.template
	rm -f alpine-${VERSION}-amd64-libvirt.box
	PACKER_KEY_INTERVAL=10ms packer build -only=alpine-${VERSION}-amd64-libvirt -on-error=abort alpine.json
	@echo BOX successfully built!
	@echo to add to local vagrant install do:
	@echo vagrant box add -f alpine-${VERSION}-amd64 alpine-${VERSION}-amd64-libvirt.box

alpine-${VERSION}-uefi-amd64-libvirt.box: answers provision.sh alpine.json Vagrantfile.template
	rm -f alpine-${VERSION}-amd64-libvirt.box
	PACKER_KEY_INTERVAL=10ms packer build -only=alpine-${VERSION}-uefi-amd64-libvirt -on-error=abort alpine.json
	@echo BOX successfully built!
	@echo to add to local vagrant install do:
	@echo vagrant box add -f alpine-${VERSION}-uefi-amd64 alpine-${VERSION}-uefi-amd64-libvirt.box

alpine-${VERSION}-amd64-virtualbox.box: answers provision.sh alpine.json Vagrantfile.template
	rm -f alpine-${VERSION}-amd64-virtualbox.box
	packer build -only=alpine-${VERSION}-amd64-virtualbox -on-error=abort alpine.json
	@echo BOX successfully built!
	@echo to add to local vagrant install do:
	@echo vagrant box add -f alpine-${VERSION}-amd64 alpine-${VERSION}-amd64-virtualbox.box

.PHONY: buid-libvirt buid-uefi-libvirt build-virtualbox
