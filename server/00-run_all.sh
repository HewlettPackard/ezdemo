#!/usr/bin/env bash

set -euo pipefail

./01-init.sh "${1}"
./02-apply.sh "${1}"
./03-install.sh "${1}"
./04-configure.sh "${1}"

exit 0
