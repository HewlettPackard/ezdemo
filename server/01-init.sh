#!/usr/bin/env bash
# =============================================================================
# Copyright 2022 Hewlett Packard Enterprise
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
# =============================================================================

USAGE="Usage: ${0} $(paste -s -d '|' providers)"

PROVIDERS=($(<providers))
if ! [ $# -gt 0 ] || ! (echo ${PROVIDERS[@]} | grep -w -q ${1}); then
  echo $USAGE
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

. ./user_settings.sh

if [ "${IS_MAPR_HA}" == "true" ]
then
   MAPR_COUNT=5
else
   MAPR_COUNT=1
fi

cat > ${1}/my.tfvars <<EOF
user = ${USER_ID}
project_id = ${PROJECT_ID// /_}
is_runtime = ${IS_RUNTIME}
is_mlops = ${IS_MLOPS}
is_ha = ${IS_HA}
is_mapr = ${IS_MAPR}
mapr_count = ${MAPR_COUNT}
admin_password = ${ADMIN_PASSWORD}
EOF
if [[ "${IS_GPU}" == "true" ]]; then
  echo "gworker_count = 1" >> ${1}/my.tfvars
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
