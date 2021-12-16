#!/usr/bin/env bash

set -euo pipefail

if ! echo "aws azure kvm vmware" | grep -w -q ${1}; then
   echo Usage: "${0} aws|azure|kvm|vmware"
   exit 1
fi

source ./outputs.sh "${1}"
./refresh_files.sh "${1}"

ANSIBLE_SSH_RETRIES=5 ${ANSIBLE_CMD} -f 10 \
  -i ./ansible/inventory.ini \
  ./ansible/install.yml

echo "Platform installion complete, gateway should be accessible at https://${GATW_PUB_DNS}/"

# Continue if completed
echo "Stage 3 complete"
# ./04-configure.sh "${1}"

exit 0
