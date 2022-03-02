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

# OUTPUT_JSON=$(cat "generated/output.json")

###############################################################################
# Set variables from terraform output
###############################################################################

# Ensure python is able to parse the OUTPUT_JSON file
# python3 - <<____HERE
# import json,sys,subprocess
# try:
#    with open('generated/output.json') as f:
#       json.load(f)
# except:
#    print(80 * '*')
#    print("ERROR: Can't parse: 'generated/output.json'")
#    print(80 * '*')
#    sys.exit(1)
# ____HERE
[[ -f generated/output.json ]] || (echo "no output" && exit 1)

###############################################################################
# Set variables from terraform output
###############################################################################
SSH_PUB_KEY_PATH="generated/controller.pub_key"
SSH_PRV_KEY_PATH="generated/controller.prv_key"
# CTRL_PRV_IPS=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (*obj["controller_private_ips"]["value"], sep=" ")')
CTRL_PRV_IPS=($(jq -r '.controller_private_ips.value[]' generated/output.json))
#echo "CTRL_PRV_IPS=${CTRL_PRV_IPS}"
# CTRL_PRV_DNS=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (*obj["controller_private_dns"]["value"], sep=" ")')
CTRL_PRV_DNS=($(jq -r '.controller_private_dns.value[]' generated/output.json))
#echo "CTRL_PRV_DNS=${CTRL_PRV_DNS}"

# GATW_PRV_IPS=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (*obj["gateway_private_ips"]["value"], sep=" ")')
GATW_PRV_IPS=($(jq -r '.gateway_private_ips.value[]' generated/output.json))
#echo "GATW_PRV_IPS=${GATW_PRV_IPS}"
# GATW_PUB_IPS=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (*obj["gateway_public_ips"]["value"], sep=" ")')
GATW_PUB_IPS=($(jq -r '.gateway_public_ips.value[]' generated/output.json))
#echo "GATW_PUB_IPS=${GATW_PUB_IPS}"
# GATW_PRV_DNS=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (*obj["gateway_private_dns"]["value"], sep=" ")')
GATW_PRV_DNS=($(jq -r '.gateway_private_dns.value[]' generated/output.json))
#echo "GATW_PRV_DNS=${GATW_PRV_DNS}"
# GATW_PUB_DNS=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (*obj["gateway_public_dns"]["value"], sep=" ")')
GATW_PUB_DNS=($(jq -r '.gateway_public_dns.value[]' generated/output.json))
#echo "GATW_PUB_DNS=${GATW_PUB_DNS}"
# GATW_PUB_HOST=$(echo $GATW_PUB_DNS | cut -d"." -f1)
# GATW_PRV_HOST=$(echo $GATW_PRV_DNS | cut -d"." -f1)

#### WORKERS
# WORKER_COUNT=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["worker_count"]["value"], sep=" ")')
WORKER_COUNT=($(jq -r '.worker_count.value' generated/output.json))
# WRKR_PRV_IPS=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (*obj["workers_private_ip"]["value"], sep=" ")')
WRKR_PRV_IPS=($(jq -r '.workers_private_ip.value[]' generated/output.json))
#echo "WRKR_PRV_IPS=${WRKR_PRV_IPS}"
#read -r -a WRKR_PRV_IPS <<< "$WRKR_PRV_IPS"

#### GPU WORKERS
# GWORKER_COUNT=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["gworker_count"]["value"], sep=" ")')
GWORKER_COUNT=($(jq -r '.gworker_count.value' generated/output.json))
# GWRKR_PRV_IPS=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (*obj["gworkers_private_ip"]["value"], sep=" ")')
GWRKR_PRV_IPS=($(jq -r '.gworkers_private_ip.value[]' generated/output.json))
#echo "GWRKR_PRV_IPS=${GWRKR_PRV_IPS}"

#### MAPR NODES
# MAPR_COUNT=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["mapr_count"]["value"], sep=" ")')
MAPR_COUNT=($(jq -r '.mapr_count.value' generated/output.json))
# MAPR_PRV_IPS=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (*obj["mapr_private_ips"]["value"], sep=" ")')
MAPR_PRV_IPS=($(jq -r '.mapr_private_ips.value[]' generated/output.json))
#echo "MAPR_PRV_IPS=${MAPR_PRV_IPS}"
#read -r -a WRKR_PRV_IPS <<< "$WRKR_PRV_IPS"

# AD_PRV_IP=$(echo $OUTPUT_JSON | python3 -c 'import json,sys;obj=json.load(sys.stdin);print (obj["ad_server_private_ip"]["value"])')
AD_PRV_IP=($(jq -r '.ad_server_private_ip.value' generated/output.json))
#echo "AD_PRV_IP=${AD_PRV_IP}"

### SYSTEM SETTINGS
source ./system_settings.sh
EPIC_DL_URL=${EPIC_STABLE_URL}
[[ "${IS_STABLE}" == "false" ]] && export EPIC_DL_URL=${EPIC_LATEST_URL}

### USER SETTINGS
source ./user_settings.sh "${1}"

# echo "${EPIC_DL_URL}"
EPIC_FILENAME="$(echo ${EPIC_DL_URL##*/})"
# echo ${EPIC_FILENAME}
EPIC_OPTIONS="--skipeula --default-password ${ADMIN_PASSWORD}"

ANSIBLE_CMD="ansible-playbook"
if [ ${IS_VERBOSE} ]; then
  ANSIBLE_CMD="${ANSIBLE_CMD} -v"
fi
