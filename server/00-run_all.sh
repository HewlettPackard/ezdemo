#!/usr/bin/env bash

set -euo pipefail

if ! echo "aws azure kvm vmware mac" | grep -w -q ${1}; then
   echo Usage: "${0} aws|azure|kvm|vmware"
   exit 1
fi

if [[ -f "${1}/run.log" ]]; then 
  mv "${1}/run.log" "${1}/$(date +'%Y%m%d%H%M')-run.log"
fi

./01-init.sh "${1}" | tee "${1}/run.log"
./02-apply.sh "${1}" | tee -a "${1}/run.log"
./03-install.sh "${1}" | tee -a "${1}/run.log"
./04-configure.sh "${1}" | tee -a "${1}/run.log"

exit 0
