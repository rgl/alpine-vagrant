#!/bin/bash
# this will update the alpine.json file with the current image checksum.
set -eux
iso_url=$(jq -r '.variables.iso_url' alpine.json)
iso_checksum=$(curl -o- --silent --show-error $iso_url.sha256 | awk '{print $1}')
sed -i -E "s,(\"iso_checksum\": \")[a-z0-9:]*?(\"),\\1sha256:$iso_checksum\\2,g" alpine.json
echo 'iso_checksum updated successfully'
