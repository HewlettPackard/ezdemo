#!/usr/bin/env bash

set -euo pipefail
(ps -ef | grep "${NAME}-[d]isk1.img" | awk '{ print $2 }' | xargs sudo kill -9) || true
ip=$(cat ${NAME}.ip | cut -d',' -f1) || true
if [[ "${ip}" != "" ]];then
  ssh-keygen -R "${ip}" || true
fi
rm -rf "vms/${NAME}"
rm -f "${NAME}.ip"

exit 0
