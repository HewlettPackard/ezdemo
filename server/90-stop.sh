#!/usr/bin/env bash

ANSIBLE_CMD="ansible-playbook"
if [ ${IS_VERBOSE} ]; then
  ANSIBLE_CMD="${ANSIBLE_CMD} -v"
fi

ANSIBLE_SSH_RETRIES=5 ${ANSIBLE_CMD} -f 10 \
  -i ./ansible/inventory.ini \
  ./ansible/shutdown.yml

pushd "${1}" > /dev/null
  if [[ -f "./stop.sh" ]]; then
    "./stop.sh"
  fi
popd > /dev/null

echo "Stop complete"

exit 0