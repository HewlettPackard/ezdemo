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

set -euo pipefail

# update credentials & tags from config file

SUBSCRIPTION=$(jq '.az_subscription' ./config.json)
TENANT=$(jq '.az_tenant' ./config.json)
APPID=$(jq '.az_appId' ./config.json)
PASSWORD=$(jq '.az_password' ./config.json)
USER_ID=$(jq 'if .user == "" then "unknown user" else .user end' ./config.json)
PROJECT_ID=$(jq 'if .project_id == "" then "unnamed" else .project_id end' ./config.json)
ADMIN_PASSWORD=$(jq '.admin_password' ./config.json)
IS_MLOPS=$(jq -r '.is_mlops // false' ./config.json)
IS_MAPR=$(jq -r '.is_mapr // false' ./config.json)
IS_GPU=$(jq -r '.is_gpu // false' ./config.json)
IS_HA=$(jq -r '.is_ha // false' ./config.json)
REGION=$(jq -r '.region' ./config.json)

cat > ./my.tfvars <<EOF
subscription_id = ${SUBSCRIPTION}
client_id = ${APPID}
client_secret = ${PASSWORD}
tenant_id = ${TENANT}
user = ${USER_ID}
project_id = ${PROJECT_ID// /_}
is_mlops = ${IS_MLOPS}
is_mapr = ${IS_MAPR}
is_ha = ${IS_HA}
admin_password = ${ADMIN_PASSWORD}
EOF

if [[ "${IS_GPU}" == "true" ]]; then
  echo "gworker_count = 1" >> ./my.tfvars
fi
if [[ "${REGION}" != "" ]]; then
  echo "setting region to $REGION"
  echo "region = \"${REGION}\"" >> ./my.tfvars
fi

exit 0
