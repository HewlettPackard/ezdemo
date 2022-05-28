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

[[ -f generated/output.json ]] || (echo "no output" && exit 1)

###############################################################################
# Set variables from terraform output
###############################################################################
SSH_PUB_KEY_PATH="generated/controller.pub_key"
SSH_PRV_KEY_PATH="generated/controller.prv_key"
CTRL_PRV_IPS=($(jq -r '.controller_private_ips.value[]' generated/output.json))
CTRL_PRV_DNS=($(jq -r '.controller_private_dns.value[]' generated/output.json))

#### GATEWAYS
GATW_PRV_IPS=($(jq -r '.gateway_private_ips.value[]' generated/output.json))
GATW_PUB_IPS=($(jq -r '.gateway_public_ips.value[]' generated/output.json))
GATW_PRV_DNS=($(jq -r '.gateway_private_dns.value[]' generated/output.json))
GATW_PUB_DNS=($(jq -r '.gateway_public_dns.value[]' generated/output.json))

#### WORKERS
WORKER_COUNT=($(jq -r '.worker_count.value' generated/output.json))
WRKR_PRV_IPS=($(jq -r '.workers_private_ip.value[]' generated/output.json))

#### GPU WORKERS
GWORKER_COUNT=($(jq -r '.gworker_count.value' generated/output.json))
GWRKR_PRV_IPS=($(jq -r '.gworkers_private_ip.value[]' generated/output.json))

#### MAPR NODES
MAPR_COUNT=($(jq -r '.mapr_count.value' generated/output.json))
MAPR_PRV_IPS=($(jq -r '.mapr_private_ips.value[]' generated/output.json))

#### AD SERVER
AD_PRV_IP=($(jq -r '.ad_server_private_ip.value' generated/output.json))

### SYSTEM SETTINGS
source ./system_settings.sh
EPIC_DL_URL=${EPIC_STABLE_URL}
[[ "${IS_STABLE}" == "false" ]] && export EPIC_DL_URL=${EPIC_LATEST_URL}

### USER SETTINGS
source ./user_settings.sh

EPIC_FILENAME="$(echo ${EPIC_DL_URL##*/})"
EPIC_OPTIONS="--skipeula --default-password ${ADMIN_PASSWORD}"

ANSIBLE_CMD="ansible-playbook"
if [ ${IS_VERBOSE} ]; then
  ANSIBLE_CMD="${ANSIBLE_CMD} -v"
fi
