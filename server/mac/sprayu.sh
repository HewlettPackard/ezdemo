#!/usr/bin/env bash

set -euo pipefail

VMS=("c1a" "ada" "gwa" "w1a" "w2a")
CPUS=(4 1 4 8 8)
MEMS=(32 4 8 32 32)
DISKS=(512 0 0 512 512)

for num in {1..5}; do
  id=num-1
  # echo "Creating ${VMS[id]}"
  ./ubuntu-arm.sh "${VMS[id]}" "${CPUS[id]}" "${MEMS[id]}" "${DISKS[id]}"
done

echo "Done."
exit 0
