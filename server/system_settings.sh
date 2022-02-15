#!/usr/bin/env bash

USAGE="Usage: ${0} $(paste -s -d '|' providers)"

PROVIDERS=($(<providers))
if ! [ $# -gt 0 ] || ! (echo ${PROVIDERS[@]} | grep -w -q ${1}); then
  echo $USAGE
  exit 1
fi

set -euo pipefail

EPIC_STABLE_URL=$(jq -r '.epic_stable' ./system.settings)
EPIC_LATEST_URL=$(jq -r '.epic_latest' ./system.settings)
IS_RUNTIME=$(jq -r '.is_runtime' ./system.settings)
IS_STABLE=$(jq '.is_stable' ./system.settings)
K8S_VERSION=$(jq '.k8s_version' ./system.settings)
APP_VERSION=$(jq '.version' ./system.settings)
