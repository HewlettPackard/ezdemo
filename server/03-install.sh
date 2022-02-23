#!/usr/bin/env bash

USAGE="Usage: ${0} $(paste -s -d '|' providers)"

PROVIDERS=($(<providers))
if ! [ $# -gt 0 ] || ! (echo ${PROVIDERS[@]} | grep -w -q ${1}); then
  echo $USAGE
  exit 1
fi

set -euo pipefail

./refresh_files.sh "${1}"
source ./outputs.sh "${1}"

ANSIBLE_SSH_RETRIES=5 ${ANSIBLE_CMD} -f 10 \
  -i ./ansible/inventory.ini \
  ./ansible/install.yml

echo "Platform installion complete, gateway should be accessible at https://${GATW_PUB_DNS}/"

echo "Stage 3 complete"

exit 0
