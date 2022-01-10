#!/usr/bin/env bash

set -euo pipefail

sudo killall qemu-system-x86_64 || true

for vm in $(<hosts.out);do
  name=$(echo ${vm} | cut -d',' -f1)
  ip=$(echo ${vm} | cut -d',' -f2)
  ssh-keygen -R "${ip}" || true
  rm -rf "vms/${name}"
done
# rm -f ansible/inventory.ini || true
rm -f hosts.out || true
# rm -f ca-* || true
# rm -f run.log || true
# rm -f adconf.json || true

exit 0
