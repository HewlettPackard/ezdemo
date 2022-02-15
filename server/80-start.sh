#!/usr/bin/env bash

USAGE="Usage: ${0} $(paste -s -d '|' providers)"

PROVIDERS=($(<providers))
if ! [ $# -gt 0 ] || ! (echo ${PROVIDERS[@]} | grep -w -q ${1}); then
  echo $USAGE
  exit 1
fi

set -euo pipefail

pushd "${1}" > /dev/null
  if [[ -f "./start.sh" ]]; then
    "./start.sh"
  fi
popd > /dev/null

./10-refresh.sh "${1}"

echo "Start complete"

exit 0