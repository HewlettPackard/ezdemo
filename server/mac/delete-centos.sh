#!/usr/bin/env bash

set -euo pipefail

# echo "CAME: ${1:- none}"

for vm in $(ls vms/);do
  (ps -ef | grep "$vm-[d]isk1.img" | awk '{ print $2 }' | xargs sudo kill -9) || true
  name=$(echo ${vm} | cut -d',' -f1)
  ip=$(echo ${vm} | cut -d',' -f2)
  ssh-keygen -R "${ip}" || true
  rm -f ${name}-debug.log || true
  rm -rf "vms/${name}"
done

rm -f hosts.out || true

exit 0
