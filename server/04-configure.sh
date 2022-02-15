#!/usr/bin/env bash

USAGE="Usage: ${0} $(paste -s -d '|' providers)"

PROVIDERS=($(<providers))
if ! [ $# -gt 0 ] || ! (echo ${PROVIDERS[@]} | grep -w -q ${1}); then
  echo $USAGE
  exit 1
fi

set -euo pipefail

source ./outputs.sh "${1}"

ANSIBLE_SSH_RETRIES=5 ${ANSIBLE_CMD} -f 10 \
  -i ./ansible/inventory.ini \
  ./ansible/configure.yml

echo "Stage 4 complete"

exit 0
