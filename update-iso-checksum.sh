#!/bin/bash
# this will update the alpine.pkr.hcl file with the current image checksum.
set -eux
iso_url="$(perl -ne '/default\s*=\s*\"(https:.+\.alpinelinux\.org.+)\"/ && print $1' <alpine.pkr.hcl)"
iso_checksum=$(curl -o- --silent --show-error $iso_url.sha256 | awk '{print $1}')
sed -i -E "s,(default\s*=\s*\")(sha256:[a-z0-9]+)(\"),\\1sha256:$iso_checksum\\3,g" alpine.pkr.hcl
echo 'iso_checksum updated successfully'
