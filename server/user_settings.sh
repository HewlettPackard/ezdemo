#!/usr/bin/env bash

USAGE="Usage: ${0} $(paste -s -d '|' providers)"

PROVIDERS=($(<providers))
if ! [ $# -gt 0 ] || ! (echo ${PROVIDERS[@]} | grep -w -q ${1}); then
  echo $USAGE
  exit 1
fi

set -euo pipefail

IS_VERBOSE=$(jq 'if has("is_verbose") then .is_verbose else false end' "${1}"/config.json)
IS_MLOPS=$(jq 'if has("is_mlops") then .is_mlops else false end' "${1}"/config.json)
IS_MAPR=$(jq 'if has("is_mapr") then .is_mapr else false end' "${1}"/config.json)
IS_HA=$(jq 'if has("is_ha") then .is_ha else false end' "${1}"/config.json)
ADMIN_PASSWORD=$(jq '.admin_password' "${1}"/config.json)
