#!/usr/bin/env bash

set -euo pipefail

source ./outputs.sh "${1}"

ANSIBLE_SSH_RETRIES=5 ${ANSIBLE_CMD} -f 10 \
  -i ./ansible/inventory.ini \
  ./ansible/configure.yml

echo "Stage 4 complete"

exit 0
