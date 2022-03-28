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
REGION=$(jq -r '.region' ./config.json)

cat >> ./my.tfvars <<EOF
subscription_id = ${SUBSCRIPTION}
client_id = ${APPID}
client_secret = ${PASSWORD}
tenant_id = ${TENANT}
EOF

if [[ "${REGION}" != "" ]]; then
  echo "region = \"${REGION}\"" >> ./my.tfvars
fi

exit 0
