#!/usr/bin/env bash

pushd "${1}" > /dev/null
  if [[ -f "./start.sh" ]]; then
    "./start.sh"
  fi
popd > /dev/null

./10-refresh.sh "${1}"

echo "Start complete"

exit 0