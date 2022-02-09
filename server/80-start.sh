#!/usr/bin/env bash

set -euo pipefail

if ! echo "aws azure kvm vmware mac" | grep -w -q ${1}; then
   echo Usage: "${0} aws|azure|kvm|vmware"
   exit 1
fi

pushd "${1}" > /dev/null
  if [[ -f "./start.sh" ]]; then
    "./start.sh"
  fi
popd > /dev/null

./10-refresh.sh "${1}"

echo "Start complete"

exit 0