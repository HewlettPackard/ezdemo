#!/usr/bin/env bash

USAGE="Usage: ${0} $(paste -s -d '|' providers)"

PROVIDERS=($(<providers))
if ! [ $# -gt 0 ] || ! (echo ${PROVIDERS[@]} | grep -w -q ${1}); then
  echo $USAGE
  exit 1
fi

if [[ "${1}" == "mac" && "$(uname -s)" != "Darwin" ]]
then
  echo "You should be running this on MacOS"
  exit 1
fi

set -euo pipefail

[[ -d "./generated" ]] || mkdir generated

if [[ ! -f  "./generated/controller.prv_key" ]]; then
   ssh-keygen -m pem -t rsa -N "" -f "./generated/controller.prv_key"
   mv "./generated/controller.prv_key.pub" "./generated/controller.pub_key"
   chmod 600 "./generated/controller.prv_key"
fi

SSH_PUB_KEY=$(cat ./generated/controller.pub_key)
SSH_PRV_KEY=$(cat ./generated/controller.prv_key)
SSH_PRV_KEY_B64=$(base64 ./generated/controller.prv_key)

if [[ ! -f "./generated/cloud-init.yaml" ]]; then
   CLOUD_INIT=$(eval "cat <<EOF
$(<./etc/cloud-init.yaml-template)
EOF
" 2> /dev/null)

   echo "$CLOUD_INIT" > ./generated/cloud-init.yaml
fi

pushd "${1}" > /dev/null
   TF_IN_AUTOMATION=1 terraform init -upgrade ${EZWEB_TF:-}
   ### Init hook-up for individual targets (aws, vmware etc)
   if [[ -f "./init.sh" ]]; then
      "./init.sh"
   fi
popd > /dev/null

echo "Stage 1 complete"

exit 0
